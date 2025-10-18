INSERT INTO style_template (name, description, prompt, negative_prompt, seed, steps, sampler, guidance_scale, meta_data)
VALUES
('Beach Day', 'Bright outdoor beach lifestyle scene', 'A person enjoying a sunny beach day with ocean background', 'low quality, blurry', 42, 30, 'Euler', 7.5, '{"theme":"beach","mood":"sunny"}'),

('Urban Street', 'Trendy urban fashion on city streets', 'Street style fashion shoot with modern city background', 'low quality, cartoonish', 77, 30, 'Euler', 7.5, '{"theme":"urban","mood":"trendy"}'),

('Fashion Studio', 'Professional indoor fashion studio shoot', 'Studio photoshoot with soft lighting and plain background', 'overexposed, cluttered', 101, 40, 'DPM++', 8.0, '{"theme":"studio","mood":"professional"}'),

('Home Decor', 'Lifestyle product photography in home interiors', 'Living room styled with modern home decor and cozy lighting', 'messy background, low quality', 202, 35, 'Euler a', 7.0, '{"theme":"home","mood":"cozy"}'),

('Festive Look', 'Celebration style with cultural festive mood', 'Model in festive outfit with colorful decorations and lights', 'dark, dull, empty background', 303, 35, 'DPM++', 8.5, '{"theme":"festive","mood":"vibrant"}');


-- 🔸 Seed Data
INSERT INTO subscription_plan (name, price, credits, description) VALUES
('Starter', 5.00, 20, 'Starter Plan - $5 for 20 images'),
('Growth', 10.00, 50, 'Growth Plan - $10 for 50 images'),
('Pro', 20.00, 100, 'Pro Plan - $20 for 100 images');
