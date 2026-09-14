-- Os sweeps só invocavam as functions quando havia item 'pending'. O resgate
-- de item preso em 'processing' (lease da 20260819210000) vive dentro das
-- claim RPCs, que só rodam quando a function é chamada: numa fila sem mensagem
-- nova, o item travado esperava a próxima mensagem chegar — de madrugada,
-- horas. Agora lease vencido também dispara a invocação; o claim decide entre
-- resgatar (retry_count < 4) e marcar como falha definitiva.
--
-- Os intervalos são os mesmos dos claims (10 min orquestrador, 5 min envio).
-- cron.schedule com um nome existente substitui o comando do job.

SELECT cron.schedule(
  'nina-orchestrator-sweep',
  '* * * * *',
  $job$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'edge_project_url')
           || '/functions/v1/nina-orchestrator',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'edge_service_role_key')
    ),
    body := '{"triggered_by": "cron-sweep"}'::jsonb,
    timeout_milliseconds := 30000
  )
  WHERE EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'edge_project_url')
    AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'edge_service_role_key')
    AND EXISTS (
      SELECT 1 FROM public.nina_processing_queue
      WHERE (status = 'pending' AND (scheduled_for IS NULL OR scheduled_for <= now()))
         OR (status = 'processing' AND updated_at < now() - interval '10 minutes')
    );
  $job$
);

SELECT cron.schedule(
  'send-queue-sweep',
  '* * * * *',
  $job$
  SELECT net.http_post(
    url := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'edge_project_url')
           || '/functions/v1/whatsapp-sender',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'edge_service_role_key')
    ),
    body := '{"triggered_by": "cron-sweep"}'::jsonb,
    timeout_milliseconds := 30000
  )
  WHERE EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'edge_project_url')
    AND EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name = 'edge_service_role_key')
    AND EXISTS (
      SELECT 1 FROM public.send_queue
      WHERE (status = 'pending' AND (scheduled_at IS NULL OR scheduled_at <= now()))
         OR (status = 'processing' AND updated_at < now() - interval '5 minutes')
    );
  $job$
);
