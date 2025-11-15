# Ecosystem Application Payment Integration

## Overview
Integrated $20 fixed application fee payment processing for ecosystem business service applications. Users must pay before application submission.

## Payment Flow (Recommended Approach)

```
1. User fills application form
   └─ Validates all required fields

2. Click "Review & Pay" button
   └─ Client-side validation
   └─ Form data prepared

3. Save application as DRAFT
   └─ POST to business_applications table
   └─ Status: 'draft'
   └─ Payment_status: 'pending'
   └─ Returns: application_id

4. Navigate to Payment Summary Page
   └─ Shows: Application details
   └─ Shows: $20.00 fee
   └─ Shows: What's included
   └─ Button: "Proceed to Secure Payment"

5. Navigate to Payment Processing Page
   └─ Shows: Secure payment badge
   └─ Form: Card details (simulated)
   └─ Creates: Payment record in application_payments
   └─ Processes: Payment (currently simulated)

6. Payment Success
   └─ Update application_payments.status = 'succeeded'
   └─ Trigger: Auto-update business_applications.status = 'paid'
   └─ Trigger: Auto-update payment_status = 'completed'

7. Navigate to Success Page
   └─ Shows: Success animation
   └─ Shows: Receipt with application ID
   └─ Shows: What's next steps
   └─ Email: Confirmation sent (via database trigger)
   └─ Button: "Track Status" | "Go Home"
```

## Database Schema

### New Columns in `business_applications`
```sql
status VARCHAR(20) DEFAULT 'draft'
  -- Values: 'draft', 'pending_payment', 'paid', 'under_review', 'approved', 'rejected'

payment_status VARCHAR(20)
  -- Values: 'pending', 'processing', 'completed', 'failed', 'refunded'

payment_id VARCHAR(255)
  -- Stripe payment intent ID or transaction reference

payment_amount DECIMAL(10,2) DEFAULT 20.00
  -- Application fee (fixed at $20)

paid_at TIMESTAMPTZ
  -- Timestamp when payment completed
```

### New Table: `application_payments`
```sql
CREATE TABLE application_payments (
  id UUID PRIMARY KEY,
  application_id UUID REFERENCES business_applications(id),
  user_id UUID REFERENCES users(id),
  amount DECIMAL(10,2) DEFAULT 20.00,
  currency VARCHAR(3) DEFAULT 'USD',
  payment_method VARCHAR(50),  -- 'stripe', 'paypal', 'card'
  payment_intent_id VARCHAR(255) UNIQUE,
  status VARCHAR(20) DEFAULT 'pending',
  error_message TEXT,
  receipt_url TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Files Created/Modified

### Database Migration
- **`/supabase/migrations/add_payment_support_to_ecosystem_applications.sql`**
  - Adds payment columns to business_applications
  - Creates application_payments table
  - Sets up RLS policies
  - Creates triggers for auto-sync payment status
  - Indexes for performance

### Models
- **`/lib/models/application_status.dart`**
  - ApplicationStatus enum (draft, pending_payment, paid, under_review, approved, rejected)
  - PaymentStatus enum (pending, processing, completed, failed, refunded)
  - Display name helpers

- **`/lib/models/payment_model.dart`**
  - PaymentModel class with all payment fields
  - fromJson/toJson methods
  - copyWith helper

### Services
- **`/lib/services/application_payment_service.dart`**
  - `createPayment()` - Create payment record
  - `processPayment()` - Process payment (simulated)
  - `getPaymentForApplication()` - Fetch payment details
  - `getUserPayments()` - List user's payments
  - `isApplicationPaid()` - Check payment status
  - `requestRefund()` - Handle refunds
  - `generateReceipt()` - Create receipt data
  - Fixed fee: $20.00

- **`/lib/services/business_application_service.dart`** (Updated)
  - `saveDraftApplication()` - Save as draft before payment
  - `markApplicationAsPaid()` - Update status after payment
  - `getApplicationById()` - Fetch single application
  - Kept existing submitApplication() for backward compatibility

### UI Pages
- **`/lib/features/ecosystem/payment_summary_page.dart`**
  - Shows application summary
  - Displays $20 fee in gradient card
  - Lists "What's Included" benefits
  - "Proceed to Secure Payment" button
  - Clean, modern UI with glassmorphism

- **`/lib/features/ecosystem/payment_processing_page.dart`**
  - Secure payment badge
  - Card payment form (simulated)
  - Shows total amount
  - Loading state during processing
  - Error handling with retry
  - Navigates to success on completion

- **`/lib/features/ecosystem/payment_success_page.dart`**
  - Success animation (green checkmark)
  - Receipt card with all details
  - Receipt number: FV-{app_id}
  - Copy application ID button
  - "What's Next" steps
  - Track Status | Go Home buttons

- **`/lib/features/ecosystem/business_services_portal.dart`** (Updated)
  - Changed submit button: "Submit Request" → "Review & Pay"
  - Updated submit logic to call `saveDraftApplication()`
  - Navigates to PaymentSummaryPage instead of success view
  - Added payment_summary_page import

## Payment Features

### Security
✅ Simulated payment processing (ready for Stripe integration)
✅ RLS policies on payment tables
✅ User authentication required
✅ Secure payment badge UI
✅ Database triggers for status sync

### User Experience
✅ Clear 3-step flow (Review → Pay → Success)
✅ Application saved as draft (no data loss on payment failure)
✅ Receipt with application ID
✅ Copy-to-clipboard functionality
✅ Email confirmation (via existing triggers)
✅ What's Next guidance
✅ Track status option (placeholder)

### Admin Features
✅ All payments audit trail in application_payments table
✅ Payment status synced to applications automatically
✅ Refund capability built-in
✅ Admin can view all payments (RLS policy)
✅ Metadata field for extra payment data

## Application Status Flow

```
Draft → Pending Payment → Paid → Under Review → Approved/Rejected
  ↓          ↓              ↓
Saved    Awaiting       Payment
         Payment       Succeeded
```

## Payment Status Flow

```
Pending → Processing → Completed
   ↓                      ↓
Failed              Can be Refunded
```

## Stripe Integration (Future)

Currently using **simulated payment** for testing. To integrate real Stripe:

### 1. Add Stripe Package
```yaml
# pubspec.yaml
dependencies:
  flutter_stripe: ^10.0.0
```

### 2. Create Supabase Edge Function
```typescript
// supabase/functions/create-payment-intent/index.ts
import Stripe from 'stripe'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY'))

serve(async (req) => {
  const { amount, applicationId } = await req.json()
  
  const paymentIntent = await stripe.paymentIntents.create({
    amount: amount * 100, // Convert to cents
    currency: 'usd',
    metadata: { application_id: applicationId },
  })
  
  return new Response(JSON.stringify({
    clientSecret: paymentIntent.client_secret
  }))
})
```

### 3. Update Payment Service
```dart
// Replace simulated processing with:
final response = await Supabase.instance.client.functions.invoke(
  'create-payment-intent',
  body: {'amount': 20.00, 'applicationId': applicationId},
);

final clientSecret = response.data['clientSecret'];

// Show Stripe payment sheet
await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    paymentIntentClientSecret: clientSecret,
    merchantDisplayName: 'FounderVers',
  ),
);

await Stripe.instance.presentPaymentSheet();
```

### 4. Add Webhook Handler
```typescript
// supabase/functions/stripe-webhook/index.ts
// Handle payment_intent.succeeded event
// Update application_payments.status = 'succeeded'
```

## Email Notifications

Existing database triggers automatically send emails on application status changes:

1. **Applicant Confirmation Email**
   - Sent when status changes to 'paid'
   - Includes application ID, service type, next steps
   - Receipt attached (if configured)

2. **Admin Notification Email**
   - Sent when new application is paid
   - Includes applicant details, service requested
   - Link to admin dashboard

## Testing Checklist

### Manual Testing
- [ ] Fill out application form with all fields
- [ ] Click "Review & Pay" → Validates form
- [ ] Payment Summary page shows correct details
- [ ] Payment Summary shows $20.00 fee
- [ ] Click "Proceed to Secure Payment"
- [ ] Payment Processing page loads
- [ ] Enter simulated card details
- [ ] Click "Pay $20.00" button
- [ ] Loading spinner shows
- [ ] Success page appears with checkmark
- [ ] Receipt shows correct application ID
- [ ] Copy Application ID works
- [ ] Go Home button navigates to HomePage
- [ ] Check database: application status = 'paid'
- [ ] Check database: payment record exists
- [ ] Verify email sent to applicant

### Database Testing
```sql
-- Check draft application saved
SELECT * FROM business_applications 
WHERE status = 'draft' 
ORDER BY created_at DESC LIMIT 1;

-- Check payment created
SELECT * FROM application_payments 
ORDER BY created_at DESC LIMIT 1;

-- Check status updated after payment
SELECT status, payment_status, paid_at 
FROM business_applications 
WHERE id = '<application_id>';

-- Check trigger worked
SELECT * FROM application_payments ap
JOIN business_applications ba ON ap.application_id = ba.id
WHERE ap.status = 'succeeded' AND ba.status = 'paid';
```

### Error Handling Tests
- [ ] Submit with invalid form → Shows validation errors
- [ ] Payment fails → Shows error message
- [ ] Payment fails → Application stays as draft
- [ ] Retry payment after failure
- [ ] User closes page mid-payment → Draft preserved

## Migration Steps

1. **Apply Database Migration**
```bash
cd supabase
psql $DATABASE_URL -f migrations/add_payment_support_to_ecosystem_applications.sql
```

2. **Verify Tables Created**
```sql
\d business_applications  -- Check new columns
\d application_payments    -- Check table exists
SELECT * FROM pg_trigger WHERE tgrelid = 'application_payments'::regclass;
```

3. **Test Payment Flow**
- Open app → Navigate to Ecosystem → Select service
- Fill form → Click "Review & Pay"
- Verify payment summary appears
- Complete simulated payment
- Check success page

4. **Monitor Logs**
```sql
-- Check for payment records
SELECT COUNT(*) FROM application_payments;

-- Check for paid applications
SELECT COUNT(*) FROM business_applications WHERE status = 'paid';
```

## Benefits of This Approach

✅ **No Data Loss**: Application saved as draft before payment
✅ **Clear UX**: 3-step flow is intuitive (Review → Pay → Success)
✅ **Audit Trail**: Every payment tracked in database
✅ **Retry Capability**: Failed payments don't lose form data
✅ **Email Confirmation**: Automatic via existing triggers
✅ **Admin Visibility**: Full payment history accessible
✅ **Scalable**: Ready for real Stripe integration
✅ **Secure**: RLS policies, user authentication
✅ **Professional**: Modern UI with receipts

## Next Steps (Optional Enhancements)

1. **Real Stripe Integration**
   - Add Flutter Stripe package
   - Create Edge Functions for payment processing
   - Set up webhooks for async updates

2. **Application Tracking Dashboard**
   - User can view all applications
   - Show status history
   - Download receipts

3. **Refund System**
   - Admin panel to process refunds
   - Automated refund emails
   - Status rollback to draft

4. **Multiple Payment Methods**
   - PayPal integration
   - Apple Pay / Google Pay
   - Bank transfer option

5. **Dynamic Pricing**
   - Different fees per service type
   - Discount codes/coupons
   - Referral credits

6. **Email Enhancements**
   - PDF receipt attachment
   - Custom email templates
   - Payment reminders for drafts

---

**Status**: ✅ Implementation Complete (Simulated Payment)
**Date**: January 2025
**Fee**: $20.00 Fixed Application Fee
**Next**: Deploy migration and test complete flow
