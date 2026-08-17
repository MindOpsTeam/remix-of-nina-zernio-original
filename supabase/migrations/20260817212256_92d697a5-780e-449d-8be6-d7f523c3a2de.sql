CREATE OR REPLACE FUNCTION public.bootstrap_agent_workspace(_workspace_name text, _config jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_workspace uuid;
  v_agent uuid;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Usuário não autenticado';
  END IF;

  SELECT wm.workspace_id INTO v_workspace
  FROM public.workspace_members wm
  JOIN public.workspaces w ON w.id = wm.workspace_id AND w.status = 'active'
  WHERE wm.user_id = v_user AND wm.status = 'active'
  ORDER BY wm.created_at
  LIMIT 1;

  IF v_workspace IS NULL THEN
    -- Arquitetura single-tenant: entra no workspace existente em vez de criar um paralelo.
    SELECT id INTO v_workspace FROM public.workspaces WHERE status = 'active' ORDER BY created_at LIMIT 1;

    IF v_workspace IS NULL THEN
      INSERT INTO public.workspaces (name, slug, created_by)
      VALUES (
        COALESCE(NULLIF(btrim(_workspace_name), ''), 'Workspace'),
        'ws-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 12),
        v_user
      )
      RETURNING id INTO v_workspace;
    END IF;

    INSERT INTO public.workspace_members (workspace_id, user_id, role, can_publish_agent, status)
    VALUES (v_workspace, v_user, 'admin', true, 'active')
    ON CONFLICT (workspace_id, user_id) DO UPDATE
      SET status = 'active', role = 'admin', can_publish_agent = true;
  END IF;

  SELECT id INTO v_agent FROM public.agents WHERE workspace_id = v_workspace LIMIT 1;

  IF v_agent IS NULL THEN
    INSERT INTO public.agents (workspace_id, created_by, updated_by)
    VALUES (v_workspace, v_user, v_user)
    RETURNING id INTO v_agent;
  END IF;

  INSERT INTO public.agent_drafts (workspace_id, agent_id, config, created_by, updated_by)
  VALUES (v_workspace, v_agent, _config, v_user, v_user)
  ON CONFLICT (agent_id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.bootstrap_agent_workspace(text, jsonb) FROM public;
GRANT EXECUTE ON FUNCTION public.bootstrap_agent_workspace(text, jsonb) TO authenticated;