-- =========================================================
-- VIEW: v_store_credit_summary
-- Description: Combines store, subscription, plan, and usage info
-- Purpose: Simplified read-only view for dashboard & APIs
-- =========================================================
-- Your admin dashboard or Shopify app API responses
-- Monitoring active plans, remaining credits, and subscription details
-- Avoiding multiple table joins in API queries

CREATE OR REPLACE VIEW v_store_credit_summary AS
SELECT
    ps.id AS store_id,
    ps.platform,
    ps.store_identifier,
    ps.store_contact_name,
    ps.store_contact_email,

    ss.id AS subscription_id,
    sp.name AS plan_name,
    sp.price AS plan_price,
    sp.credits AS plan_credits,
    ss.is_active,
    ss.auto_renew,
    ss.start_date,
    ss.end_date,
    ss.shopify_subscription_id,

    uc.id AS usage_id,
    uc.total_credits,
    uc.used_credits,
    (uc.total_credits - uc.used_credits) AS remaining_credits,
    uc.reset_date,

    GREATEST(ss.updated_at, uc.updated_at) AS last_updated
FROM
    partner_store ps
LEFT JOIN store_subscription ss ON ps.id = ss.store_id AND ss.is_active = TRUE
LEFT JOIN subscription_plan sp ON ss.plan_id = sp.id
LEFT JOIN usage_credit uc ON ps.id = uc.store_id;

-- =========================================================
-- VIEW: v_usage_audit_summary
-- Description: Historical view of credit changes (deductions/bonuses)
-- Purpose: Usage tracking, analytics, and reporting
-- =========================================================

-- Usage history dashboards (per merchant)
-- Billing reconciliation with Shopify
-- AI image generation analytics (e.g., usage patterns, plan utilization)

CREATE OR REPLACE VIEW v_usage_audit_summary AS
SELECT
    ps.id AS store_id,
    ps.store_identifier,
    ps.platform,
    ps.store_contact_name,
    ps.store_contact_email,

    sp.name AS plan_name,
    sp.price AS plan_price,
    sp.credits AS plan_credits,

    ss.id AS subscription_id,
    ss.is_active AS subscription_active,
    ss.start_date AS subscription_start,
    ss.end_date AS subscription_end,
    ss.shopify_subscription_id,

    ua.id AS audit_id,
    ua.asset_generation_id,
    ua.change AS credit_change,
    CASE
        WHEN ua.change < 0 THEN 'DEDUCTION'
        WHEN ua.change > 0 THEN 'BONUS'
        ELSE 'NEUTRAL'
    END AS change_type,
    ua.reason,
    ua.created_at AS change_date
FROM
    usage_audit_log ua
LEFT JOIN partner_store ps ON ua.store_id = ps.id
LEFT JOIN store_subscription ss ON ua.subscription_id = ss.id
LEFT JOIN subscription_plan sp ON ss.plan_id = sp.id
ORDER BY
    ua.created_at DESC;
