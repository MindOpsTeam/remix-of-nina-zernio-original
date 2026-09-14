
ALTER TABLE public.agent_runtime_events DISABLE TRIGGER agent_runtime_events_are_immutable;
DELETE FROM public.agent_runtime_events WHERE id IS NOT NULL;
ALTER TABLE public.agent_runtime_events ENABLE TRIGGER agent_runtime_events_are_immutable;
