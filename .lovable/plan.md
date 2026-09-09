# Corrigir o "internal server error" no preview

## O que já foi verificado agora

- O endereço do preview responde normalmente (HTTP 200) e a página de login carrega e renderiza.
- O servidor de desenvolvimento está de pé, sem erros de compilação e sem erros de execução registrados.
- O backend responde: serviço de login ativo (retorna "credenciais inválidas" corretamente para conta falsa) e leitura de dados no banco funcionando.

Ou seja, não foi possível reproduzir a falha aqui. O erro provavelmente aparece em uma ação específica dentro do app (uma das funções do servidor) ou é uma indisponibilidade momentânea do ambiente de preview.

## Plano

1. Reiniciar o ambiente de preview e confirmar que ele volta a responder do zero (carregamento inicial, login, painel).
2. Percorrer o app autenticado de ponta a ponta com navegação automatizada, capturando telas e chamadas de rede: painel, conversas, contatos, pipeline, agenda, equipe e configurações (Agente, APIs, Canais, Calendário, Templates).
3. Registrar toda chamada que voltar com erro de servidor (500) e, para cada uma, ler o log da função correspondente para identificar a causa real.
4. Corrigir as causas encontradas nas funções do servidor afetadas e reimplantar.
5. Repetir o percurso para confirmar que nenhuma tela retorna mais erro.

## Se nada falhar no percurso

Nesse caso o erro foi do próprio ambiente de preview e não do app. Entrego o relatório do percurso (telas e chamadas verificadas) e peço a tela/ação exata onde você viu o erro para investigar direto no ponto.

## Detalhes técnicos

- Percurso via Playwright em `localhost:8080` com sessão autenticada restaurada, viewport 1280x1800, coletando `console`, `pageerror` e respostas de rede com status >= 500.
- Para cada 500, cruzar com os logs da Edge Function correspondente e com o linter do banco (RLS/grants) quando o erro vier de acesso a dados.
- Nenhuma alteração de esquema ou de política de acesso sem confirmação prévia da causa nos logs.
