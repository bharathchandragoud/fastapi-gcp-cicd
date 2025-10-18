-- Useful indexes
CREATE INDEX idx_partner_store_platform ON partner_store(platform);
CREATE INDEX idx_partner_store_email ON partner_store(store_contact_email);

-- Fast lookups for all assets of a given store
CREATE INDEX idx_asset_store_id ON asset(store_id);

-- Queries by asset type (e.g. list all 'img' assets)
CREATE INDEX idx_asset_type ON asset(asset_type);

-- Queries by creation date (for ordering or filtering)
CREATE INDEX idx_asset_created_at ON asset(created_at);

-- Useful indexes
-- Fast lookup of all images for a given asset
CREATE INDEX idx_image_asset_asset_id ON image_asset(asset_id);

-- If you often filter by resolution or format:
CREATE INDEX idx_image_asset_resolution ON image_asset(resolution);
CREATE INDEX idx_image_asset_format ON image_asset(format);

-- JSONB meta_data needs a GIN index for fast key/value queries
CREATE INDEX idx_image_asset_meta_data_gin ON image_asset USING gin(meta_data);

-- Optional indexes for faster queries
CREATE INDEX idx_video_asset_asset_id ON video_asset(asset_id);
CREATE INDEX idx_video_asset_resolution ON video_asset(resolution);
CREATE INDEX idx_video_asset_format ON video_asset(format);
CREATE INDEX idx_video_asset_meta_data_gin ON video_asset USING gin(meta_data);

-- Indexes
CREATE INDEX idx_audio_asset_asset_id ON audio_asset(asset_id);
CREATE INDEX idx_audio_asset_format ON audio_asset(format);
CREATE INDEX idx_audio_asset_meta_data_gin ON audio_asset USING gin(meta_data);

-- Indexes
CREATE INDEX idx_asset_generation_asset_id ON asset_generation(asset_id);
CREATE INDEX idx_asset_generation_request_id ON asset_generation(request_id);
CREATE INDEX idx_asset_generation_model_name ON asset_generation(model_name);
CREATE INDEX idx_asset_generation_status ON asset_generation(status);
CREATE INDEX idx_asset_generation_output_meta_data_gin ON asset_generation USING gin(output_meta_data);

-- Indexes
CREATE INDEX idx_style_store_id ON style_template(store_id);
CREATE INDEX idx_style_name_lower ON style_template(LOWER(name));
CREATE INDEX idx_style_global_templates ON style_template(store_id) WHERE store_id IS NULL;
CREATE INDEX idx_style_created_by ON style_template(created_by);
CREATE INDEX idx_style_meta_data_gin ON style_template USING gin (meta_data);

CREATE INDEX idx_batch_job_created_at ON public.batch_job USING btree (created_at DESC);
CREATE INDEX idx_batch_job_status ON public.batch_job USING btree (status);
CREATE INDEX idx_batch_job_store ON public.batch_job USING btree (store_id);

-- Indexes
CREATE INDEX idx_batch_job_asset_job ON batch_job_asset(batch_job_id);
CREATE INDEX idx_batch_job_asset_asset ON batch_job_asset(asset_id);
CREATE INDEX idx_batch_job_asset_status ON batch_job_asset(status);

-- Indexes for fast lookup
CREATE INDEX idx_attempts_generation_id ON asset_generation_attempts(generation_id);
CREATE INDEX idx_attempts_status ON asset_generation_attempts(status);

-- 🔸 Indexes
CREATE INDEX idx_subscription_plan_name ON subscription_plan (name);
CREATE INDEX idx_subscription_plan_price ON subscription_plan (price);


-- 🔸 Indexes
CREATE INDEX idx_store_subscription_store_id ON store_subscription (store_id);
CREATE INDEX idx_store_subscription_plan_id ON store_subscription (plan_id);
CREATE INDEX idx_store_subscription_shopify_id ON store_subscription (shopify_subscription_id);
CREATE INDEX idx_store_subscription_active ON store_subscription (is_active);
CREATE INDEX idx_store_subscription_dates ON store_subscription (start_date, end_date);

-- 🔸 Indexes
CREATE UNIQUE INDEX idx_usage_credit_store_id ON usage_credit (store_id);
CREATE INDEX idx_usage_credit_subscription_id ON usage_credit (subscription_id);
CREATE INDEX idx_usage_credit_usage_stats ON usage_credit (total_credits, used_credits);
CREATE INDEX idx_usage_credit_reset_date ON usage_credit (reset_date);

-- 🔸 Indexes
CREATE INDEX idx_usage_audit_log_store_id ON usage_audit_log (store_id);
CREATE INDEX idx_usage_audit_log_subscription_id ON usage_audit_log (subscription_id);
CREATE INDEX idx_usage_audit_log_asset_generation_id ON usage_audit_log (asset_generation_id);
CREATE INDEX idx_usage_audit_log_created_at ON usage_audit_log (created_at DESC);

CREATE INDEX idx_dlq_generation_id ON dead_letter_log(generation_id);