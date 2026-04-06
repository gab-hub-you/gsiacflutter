-- ============================================================
-- GSIAC/ULGDSP — Seed Beneficiary Programs (One-Time)
-- Run this ONCE on Supabase SQL Editor to populate default programs.
-- After this, manage programs via the Next.js admin panel.
-- ============================================================

INSERT INTO public.beneficiary_programs (id, name, description, type, requirements, payment_schedule, amount)
VALUES
  (
    '64a7c06c-8ab8-4e35-9d22-6789b7e9b0d1',
    '4Ps (Pantawid Pamilya)',
    'A human development measure of the national government that provides conditional cash grants to the poorest of the poor.',
    'financial',
    '["ID Card", "Barangay Indigency", "Family Photo"]',
    'Monthly',
    1500.0
  ),
  (
    'f2a4b8c1-d9e0-4f3a-a1b2-c3d4e5f6a7b8',
    'Senior Citizen Social Pension',
    'Additional government assistance to indigent senior citizens to augment their daily subsistence and medical needs.',
    'financial',
    '["OSCA ID", "Birth Certificate"]',
    'Quarterly',
    3000.0
  ),
  (
    '3e4f5a6b-7c8d-9e0f-1a2b-3c4d5e6f7a8b',
    'TUPAD Program',
    'Tulong Panghanapbuhay sa Ating Disadvantaged/Displaced Workers is a community-based package of assistance that provides emergency employment.',
    'financial',
    '["Valid ID", "Certificate of No Income"]',
    'Project-based',
    5000.0
  ),
  (
    '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
    'Municipal Scholarship',
    'Financial assistance for deserving students residing in the municipality to pursue higher education.',
    'scholarship',
    '["Report Card", "Indigency Certificate", "Enrollment Form"]',
    'Semesteral',
    10000.0
  ),
  (
    'd9f8e7d6-c5b4-a392-8170-6543210fedcb',
    'AICS (Crisis Assistance)',
    'Assistance to Individuals in Crisis Situations (AICS) provides immediate help for medical, burial, or transportation needs.',
    'financial',
    '["Medical Certificate", "Death Certificate", "Indigency"]',
    'One-time',
    2000.0
  ),
  (
    'a1b2c3d4-e5f6-a7b8-c9d0-e1f2a3b4c5d6',
    'PWD Benefits',
    'Provides discounts and financial support to Persons with Disabilities to assist with medical and livelihood needs.',
    'discount',
    '["PWD ID", "Medical Assessment"]',
    'Lifetime',
    NULL
  ),
  (
    'b2c3d4e5-f6a7-b8c9-d0e1-f2a3b4c5d6e7',
    'Farmer''s Financial Subsidy',
    'Subsidy for registered farmers to assist with agricultural inputs and livelihood support during lean months.',
    'financial',
    '["RSBSA Registration", "Valid ID"]',
    'Seasonal',
    5000.0
  ),
  (
    'c3d4e5f6-a7b8-c9d0-e1f2-a3b4c5d6e7f8',
    'Solo Parent Program',
    'Comprehensive package of social development and welfare services for solo parents and their children.',
    'discount',
    '["Solo Parent ID", "Birth Certificates of Children"]',
    'Annual',
    1000.0
  )
ON CONFLICT (id) DO NOTHING;
