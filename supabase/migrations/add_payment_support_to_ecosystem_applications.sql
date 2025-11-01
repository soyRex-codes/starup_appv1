-- Add payment support to business applications
-- Migration: Add payment tracking columns and create payments table

-- 1. Add payment-related columns to business_applications
ALTER TABLE business_applications 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'draft',
ADD COLUMN IF NOT EXISTS payment_status VARCHAR(20),
ADD COLUMN IF NOT EXISTS payment_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS payment_amount DECIMAL(10,2) DEFAULT 20.00,
ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ;

-- Add comments for clarity
COMMENT ON COLUMN business_applications.status IS 'Application workflow status: draft, pending_payment, paid, under_review, approved, rejected';
COMMENT ON COLUMN business_applications.payment_status IS 'Payment processing status: pending, processing, completed, failed, refunded';
COMMENT ON COLUMN business_applications.payment_id IS 'Stripe payment intent ID or transaction reference';
COMMENT ON COLUMN business_applications.payment_amount IS 'Application fee amount in USD (default $20)';
COMMENT ON COLUMN business_applications.paid_at IS 'Timestamp when payment was successfully completed';

-- 2. Create application_payments table for audit trail
CREATE TABLE IF NOT EXISTS application_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  application_id BIGINT NOT NULL REFERENCES business_applications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL DEFAULT 20.00,
  currency VARCHAR(3) DEFAULT 'USD',
  payment_method VARCHAR(50), -- 'stripe', 'paypal', 'card', etc.
  payment_intent_id VARCHAR(255) UNIQUE, -- Stripe payment intent ID
  status VARCHAR(20) NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'succeeded', 'failed', 'refunded'
  error_message TEXT,
  receipt_url TEXT, -- Stripe receipt URL
  metadata JSONB, -- Additional payment data
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_application_payments_application_id ON application_payments(application_id);
CREATE INDEX IF NOT EXISTS idx_application_payments_user_id ON application_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_application_payments_status ON application_payments(status);
CREATE INDEX IF NOT EXISTS idx_application_payments_payment_intent_id ON application_payments(payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_business_applications_status ON business_applications(status);
CREATE INDEX IF NOT EXISTS idx_business_applications_payment_status ON business_applications(payment_status);

-- 3. Enable RLS on application_payments
ALTER TABLE application_payments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for application_payments
-- Users can view their own payments
CREATE POLICY "Users can view own payments"
  ON application_payments
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own payments
CREATE POLICY "Users can create own payments"
  ON application_payments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- System can update payment status (for webhooks)
CREATE POLICY "Service role can update payments"
  ON application_payments
  FOR UPDATE
  USING (true); -- Service role bypass RLS

-- Admins can view all payments
CREATE POLICY "Admins can view all payments"
  ON application_payments
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM users WHERE email = ANY(
        SELECT unnest(string_to_array(current_setting('app.admin_emails', true), ','))
      )
    )
  );

-- 4. Create function to update timestamps
CREATE OR REPLACE FUNCTION update_application_payment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger for auto-updating timestamps
DROP TRIGGER IF EXISTS trigger_update_application_payment_timestamp ON application_payments;
CREATE TRIGGER trigger_update_application_payment_timestamp
  BEFORE UPDATE ON application_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_application_payment_timestamp();

-- 6. Create function to sync payment status to application
CREATE OR REPLACE FUNCTION sync_payment_status_to_application()
RETURNS TRIGGER AS $$
BEGIN
  -- When payment succeeds, update application
  IF NEW.status = 'succeeded' AND OLD.status != 'succeeded' THEN
    UPDATE business_applications
    SET 
      status = 'paid',
      payment_status = 'completed',
      payment_id = NEW.payment_intent_id,
      paid_at = NOW()
    WHERE id = NEW.application_id;
  END IF;
  
  -- When payment fails
  IF NEW.status = 'failed' THEN
    UPDATE business_applications
    SET payment_status = 'failed'
    WHERE id = NEW.application_id;
  END IF;
  
  -- When payment is refunded
  IF NEW.status = 'refunded' THEN
    UPDATE business_applications
    SET 
      status = 'draft',
      payment_status = 'refunded'
    WHERE id = NEW.application_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger to auto-sync payment status
DROP TRIGGER IF EXISTS trigger_sync_payment_status ON application_payments;
CREATE TRIGGER trigger_sync_payment_status
  AFTER UPDATE ON application_payments
  FOR EACH ROW
  EXECUTE FUNCTION sync_payment_status_to_application();

-- 8. Update existing applications to have 'draft' status (if they don't have payment info)
UPDATE business_applications
SET status = 'draft'
WHERE status IS NULL;

-- 9. Grant necessary permissions
GRANT SELECT, INSERT ON application_payments TO authenticated;
GRANT UPDATE ON application_payments TO service_role;
