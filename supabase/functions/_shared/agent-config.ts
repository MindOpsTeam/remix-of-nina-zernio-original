interface SupabaseQueryClient {
  from: (table: string) => any;
}

export interface PublishedAgentRuntimeConfig {
  workspaceId: string;
  agentId: string;
  versionId: string;
  versionNumber: number;
  checksum: string;
  compilerVersion: string;
  compiledPrompt: string;
  config: Record<string, unknown>;
}

export interface DraftAgentRuntimeConfig {
  workspaceId: string;
  agentId: string;
  draftId: string;
  revision: number;
  config: Record<string, unknown>;
}

export async function userCanEditAgent(
  supabase: SupabaseQueryClient,
  userId: string,
): Promise<boolean> {
  const { data, error } = await supabase
    .from('workspace_members')
    .select('id')
    .eq('user_id', userId)
    .eq('status', 'active')
    .in('role', ['admin', 'editor'])
    .limit(1)
    .maybeSingle();

  if (error) {
    console.error('[AgentConfig] Failed to verify edit permission:', error);
    return false;
  }
  return Boolean(data?.id);
}

/**
 * Resolve a versão publicada do agente pertencente ao usuário da conversa.
 *
 * Não há fallback para outro workspace: se o usuário não tiver associação
 * ativa ou o agente ainda não possuir versão publicada, o atendimento falha
 * de forma segura. Não existe fallback para prompt legado.
 */
export async function fetchPublishedAgentRuntimeConfig(
  supabase: SupabaseQueryClient,
  userId: string | null | undefined,
): Promise<PublishedAgentRuntimeConfig | null> {
  if (!userId) return null;

  const { data: membership, error: membershipError } = await supabase
    .from('workspace_members')
    .select('workspace_id')
    .eq('user_id', userId)
    .eq('status', 'active')
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();

  if (membershipError) {
    console.error('[AgentConfig] Failed to resolve workspace membership:', membershipError);
    return null;
  }
  if (!membership?.workspace_id) return null;

  const { data: agent, error: agentError } = await supabase
    .from('agents')
    .select('id, published_version_id')
    .eq('workspace_id', membership.workspace_id)
    .neq('status', 'archived')
    .maybeSingle();

  if (agentError) {
    console.error('[AgentConfig] Failed to resolve workspace agent:', agentError);
    return null;
  }
  if (!agent?.published_version_id) return null;

  const { data: version, error: versionError } = await supabase
    .from('agent_versions')
    .select('id, version_number, checksum, compiler_version, compiled_prompt, config')
    .eq('id', agent.published_version_id)
    .eq('agent_id', agent.id)
    .maybeSingle();

  if (versionError) {
    console.error('[AgentConfig] Failed to resolve published agent version:', versionError);
    return null;
  }
  if (!version?.compiled_prompt) return null;

  return {
    workspaceId: membership.workspace_id,
    agentId: agent.id,
    versionId: version.id,
    versionNumber: version.version_number,
    checksum: version.checksum,
    compilerVersion: version.compiler_version || 'unknown',
    compiledPrompt: version.compiled_prompt,
    config: version.config ?? {},
  };
}

/** Resolve o rascunho atual para simulação. Nunca deve ser usado no runtime
 * real, que permanece preso à versão publicada. */
export async function fetchAgentDraftRuntimeConfig(
  supabase: SupabaseQueryClient,
  userId: string | null | undefined,
): Promise<DraftAgentRuntimeConfig | null> {
  if (!userId) return null;

  const { data: membership, error: membershipError } = await supabase
    .from('workspace_members')
    .select('workspace_id')
    .eq('user_id', userId)
    .eq('status', 'active')
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();
  if (membershipError || !membership?.workspace_id) return null;

  const { data: agent, error: agentError } = await supabase
    .from('agents')
    .select('id')
    .eq('workspace_id', membership.workspace_id)
    .neq('status', 'archived')
    .maybeSingle();
  if (agentError || !agent?.id) return null;

  const { data: draft, error: draftError } = await supabase
    .from('agent_drafts')
    .select('id, revision, config')
    .eq('agent_id', agent.id)
    .maybeSingle();
  if (draftError || !draft?.id) return null;

  return {
    workspaceId: membership.workspace_id,
    agentId: agent.id,
    draftId: draft.id,
    revision: draft.revision,
    config: draft.config ?? {},
  };
}
