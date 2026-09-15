import { supabase } from '@/integrations/supabase/client';
import type { FunctionInvokeOptions } from '@supabase/functions-js';

/**
 * Invoca uma Edge Function garantindo o header Authorization com o JWT do
 * usuário. O client usa storage "brokered" no preview, e nesse cenário o
 * supabase-js nem sempre anexa o token nas chamadas de functions — o que
 * resulta em 401 ("Authorization header required" / "Unauthorized").
 */
export async function invokeFunction<T = unknown>(
  functionName: string,
  options: FunctionInvokeOptions = {},
) {
  const { data: { session } } = await supabase.auth.getSession();
  const headers: Record<string, string> = {
    ...(options.headers as Record<string, string> | undefined),
  };

  if (session?.access_token && !headers.Authorization) {
    headers.Authorization = `Bearer ${session.access_token}`;
  }

  return supabase.functions.invoke<T>(functionName, { ...options, headers });
}
