-- Recria triggers essenciais após remix:
-- 1. auto_create_deal_on_contact: cria um deal no primeiro estágio ativo quando um contato é inserido.
-- 2. update_conversation_last_message_trigger: mantém last_message_at (conversations) e last_activity (contacts) atualizados.
-- 3. updated_at triggers para tabelas com coluna updated_at.

-- 1. Criação automática de deal ao criar contato
CREATE OR REPLACE FUNCTION public.auto_create_deal_on_contact()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_stage_id uuid;
BEGIN
  -- Busca o primeiro estágio ativo e não-sistema para iniciar o lead
  SELECT id INTO v_stage_id
  FROM public.pipeline_stages
  WHERE is_active = true
    AND (is_system = false OR is_system IS NULL)
  ORDER BY position ASC
  LIMIT 1;

  -- Se não houver estágio configurado, não quebra o INSERT do contato
  IF v_stage_id IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.deals (
    contact_id,
    title,
    stage_id,
    stage,
    user_id,
    value,
    priority
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.name, 'Lead'),
    v_stage_id,
    'new',
    NEW.user_id,
    0,
    'medium'
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS auto_create_deal_on_contact ON public.contacts;
CREATE TRIGGER auto_create_deal_on_contact
AFTER INSERT ON public.contacts
FOR EACH ROW
EXECUTE FUNCTION public.auto_create_deal_on_contact();

-- 2. Atualização de timestamps de conversa e contato ao inserir mensagem
CREATE OR REPLACE FUNCTION public.update_conversation_last_message_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_contact_id uuid;
BEGIN
  UPDATE public.conversations
  SET last_message_at = NEW.sent_at,
      updated_at = NOW()
  WHERE id = NEW.conversation_id;

  SELECT contact_id INTO v_contact_id
  FROM public.conversations
  WHERE id = NEW.conversation_id;

  IF v_contact_id IS NOT NULL THEN
    UPDATE public.contacts
    SET last_activity = NEW.sent_at,
        updated_at = NOW()
    WHERE id = v_contact_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_conversation_last_message_trigger ON public.messages;
CREATE TRIGGER update_conversation_last_message_trigger
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.update_conversation_last_message_trigger();

-- 3. updated_at automático para tabelas relevantes
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS contacts_updated_at ON public.contacts;
CREATE TRIGGER contacts_updated_at
BEFORE UPDATE ON public.contacts
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS conversations_updated_at ON public.conversations;
CREATE TRIGGER conversations_updated_at
BEFORE UPDATE ON public.conversations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS conversation_states_updated_at ON public.conversation_states;
CREATE TRIGGER conversation_states_updated_at
BEFORE UPDATE ON public.conversation_states
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS message_processing_queue_updated_at ON public.message_processing_queue;
CREATE TRIGGER message_processing_queue_updated_at
BEFORE UPDATE ON public.message_processing_queue
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS send_queue_updated_at ON public.send_queue;
CREATE TRIGGER send_queue_updated_at
BEFORE UPDATE ON public.send_queue
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS nina_settings_updated_at ON public.nina_settings;
CREATE TRIGGER nina_settings_updated_at
BEFORE UPDATE ON public.nina_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tag_definitions_updated_at ON public.tag_definitions;
CREATE TRIGGER tag_definitions_updated_at
BEFORE UPDATE ON public.tag_definitions
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
