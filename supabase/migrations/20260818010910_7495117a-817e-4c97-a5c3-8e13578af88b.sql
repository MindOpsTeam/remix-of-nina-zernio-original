DELETE FROM public.messages m
USING public.messages k
WHERE m.conversation_id = k.conversation_id
  AND m.from_type = 'human'
  AND k.id <> m.id
  AND k.created_at < m.created_at
  AND m.created_at - k.created_at < interval '2 minutes'
  AND coalesce(m.content,'') = coalesce(k.content,'')
  AND coalesce(m.content,'') <> '';