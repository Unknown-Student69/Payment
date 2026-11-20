-- =====================================================================
-- MedEx | Payment Module
-- File    : payment_seed.sql
-- Run AFTER payment.sql
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. Payment methods (safe to re-run)
-- ---------------------------------------------------------------------
INSERT INTO public.payment_methods (label) VALUES
    ('Cash'),
    ('GCash'),
    ('Maya'),
    ('Credit/Debit Card')
ON CONFLICT (label) DO NOTHING;

-- ---------------------------------------------------------------------
-- 2. Sample payments
--    The current Payment schema has no active foreign key to public.orders.
--    These order_id values are sample placeholders. Replace them with
--    existing Orders Module order_id values when the modules are connected.
--    The unique constraint on payments.order_id prevents duplicate samples.
-- ---------------------------------------------------------------------
INSERT INTO public.payments
    (order_id, method_id, idempotency_key, amount, amount_collected,
     is_flagged, failure_reason, status, paid_at, created_at, gateway_reference)
SELECT v.order_id,
       pm.method_id,
       v.idempotency_key,
       v.amount,
       v.amount_collected,
       v.is_flagged,
       v.failure_reason,
       v.status,
       v.paid_at,
       v.created_at,
       v.gateway_reference
FROM (VALUES
    (900001, 'seed-payment-0001', 'GCash',             250.00::NUMERIC(10,2), 250.00::NUMERIC(10,2), FALSE, NULL::TEXT,                         'paid',      NOW() - INTERVAL '2 days',       NOW() - INTERVAL '2 days 5 minutes', 'GCASH-SEED-0001'),
    (900002, 'seed-payment-0002', 'Cash',              180.00,                180.00,                FALSE, NULL,                                'collected', NOW() - INTERVAL '1 day',        NOW() - INTERVAL '1 day 10 minutes', NULL),
    (900003, 'seed-payment-0003', 'Maya',              420.00,                NULL,                  FALSE, NULL,                                'pending',   NULL,                              NOW() - INTERVAL '30 minutes',       'MAYA-SEED-0003'),
    (900004, 'seed-payment-0004', 'Credit/Debit Card', 350.00,                NULL,                  TRUE,  'Payment gateway authorization failed', 'failed',    NULL,                              NOW() - INTERVAL '3 hours',          'CARD-SEED-0004')
) AS v(order_id, idempotency_key, method_label, amount, amount_collected,
       is_flagged, failure_reason, status, paid_at, created_at, gateway_reference)
JOIN public.payment_methods pm
    ON pm.label = v.method_label
ON CONFLICT (order_id) DO NOTHING;

COMMIT;
