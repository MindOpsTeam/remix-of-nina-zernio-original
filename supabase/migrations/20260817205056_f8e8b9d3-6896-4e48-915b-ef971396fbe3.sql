-- Habilita a publicação realtime para as tabelas que o frontend observa.
-- Após remix, a publicação supabase_realtime pode estar vazia; este script
-- recria-a idempotentemente e adiciona todas as tabelas necessárias.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END
$$;

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.contacts;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.deals;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.pipeline_stages;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.teams;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.team_functions;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.team_members;
ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.appointments;
