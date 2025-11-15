-- Create premium_payments table to track premium subscription payments
CREATE TABLE IF NOT EXISTS premium_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
  subscription_type VARCHAR(20) NOT NULL CHECK (subscription_type IN ('monthly', 'annual')),
  payment_method VARCHAR(50) DEFAULT 'stripe' NOT NULL,
  payment_intent_id VARCHAR(255),
  status VARCHAR(20) DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled')),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_premium_payments_user_id ON premium_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_premium_payments_status ON premium_payments(status);
CREATE INDEX IF NOT EXISTS idx_premium_payments_payment_intent_id ON premium_payments(payment_intent_id);

-- Add RLS policies
ALTER TABLE premium_payments ENABLE ROW LEVEL SECURITY;

-- Users can view their own premium payment records
CREATE POLICY "Users can view own premium payments"
  ON premium_payments
  FOR SELECT
  USING ((select auth.uid()) = user_id);

-- Users can insert their own premium payment records
CREATE POLICY "Users can insert own premium payments"
  ON premium_payments
  FOR INSERT
  WITH CHECK ((select auth.uid()) = user_id);

-- Users can update their own premium payment records
CREATE POLICY "Users can update own premium payments"
  ON premium_payments
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_premium_payments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER premium_payments_updated_at
  BEFORE UPDATE ON premium_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_premium_payments_updated_at();

-- Add comment
COMMENT ON TABLE premium_payments IS 'Tracks premium subscription payment transactions';
