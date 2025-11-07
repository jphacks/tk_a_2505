-- ========================================
-- Modular Database Initialization
-- ========================================
--
-- This file replaces the monolithic init.sql with a modular approach
-- Each component is organized in separate files for better maintainability
--
-- Usage: Run this file instead of the original init.sql
-- ========================================

-- 1. Basic Setup and Configuration
\ir 00_setup.sql

-- 2. Extensions
\ir 01_extensions.sql

-- 3. Custom Types
\ir 02_types.sql

-- 4. Functions
\ir functions/auth_functions.sql
\ir functions/group_functions.sql
\ir functions/rating_functions.sql

-- 5. Tables (order matters due to foreign key dependencies)
\ir tables/users.sql
\ir tables/shelters.sql
\ir tables/groups.sql
\ir tables/group_members.sql
\ir tables/missions.sql
\ir tables/mission_results.sql
\ir tables/shelter_badges.sql
\ir tables/user_shelter_badges.sql
\ir tables/points.sql
\ir tables/shelter_ratings.sql

-- 6. Policies
\ir policies/user_policies.sql
\ir policies/group_policies.sql
\ir policies/general_policies.sql
\ir policies/rating_policies.sql

-- 7. Final Grants and Configuration
\ir 99_grants.sql
