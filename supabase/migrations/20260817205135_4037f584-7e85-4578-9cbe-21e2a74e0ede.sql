-- Ajusta as políticas RLS para o modelo single-tenant.
-- deals já deve estar compartilhado; appointments ainda pode ter políticas baseadas em workspace.

-- deals: garante acesso compartilhado para todos os usuários autenticados
DROP POLICY IF EXISTS "Users can manage own deals" ON public.deals;
DROP POLICY IF EXISTS "Authenticated users can access all deals" ON public.deals;

CREATE POLICY "Authenticated users can access all deals"
ON public.deals
FOR ALL
TO authenticated
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- appointments: substitui políticas baseadas em workspace por acesso compartilhado
DROP POLICY IF EXISTS "appointments_workspace_read" ON public.appointments;
DROP POLICY IF EXISTS "appointments_workspace_write" ON public.appointments;
DROP POLICY IF EXISTS "Users can manage own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Authenticated users can access all appointments" ON public.appointments;

CREATE POLICY "Authenticated users can access all appointments"
ON public.appointments
FOR ALL
TO authenticated
USING (auth.role() = 'authenticated')
WITH CHECK (auth.role() = 'authenticated');

-- Grants explícitos para as tabelas ajustadas
GRANT SELECT, INSERT, UPDATE, DELETE ON public.deals TO authenticated;
GRANT ALL ON public.deals TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.appointments TO authenticated;
GRANT ALL ON public.appointments TO service_role;
