# Nosso Açaí — Configuração

Este site é um único arquivo estático (`index.html`) — HTML, CSS e
JavaScript juntos, sem build system. Isso significa que o deploy no
Vercel é o mais simples possível.

## 1. Deploy no Vercel (sem Supabase)

Se você só quer subir o site (com o ranking "Mais Pedidos" mostrando
o estado vazio até você configurar o Supabase):

1. Crie um repositório com o `index.html` na raiz.
2. Importe o repositório no Vercel (ou arraste a pasta em
   vercel.com/new) — não precisa configurar nada, é um site estático.
3. Pronto. O pedido continua funcionando 100% pelo WhatsApp mesmo sem
   o Supabase configurado.

## 2. Ativar o ranking "Mais Pedidos" (Supabase)

O ranking guarda, na nuvem, quantas vezes cada combinação de copo foi
pedida — só para ordenar o top 3, nunca para mostrar números ao
cliente.

**Passo a passo:**

1. Crie um projeto gratuito em [supabase.com](https://supabase.com).
2. No painel do projeto, abra **SQL Editor** → **New query**, cole o
   conteúdo do arquivo `supabase_schema.sql` (incluído aqui) e clique
   em **Run**. Isso cria a tabela `combo_counts`, a função
   `increment_combo` e as permissões corretas (RLS).
3. Vá em **Project Settings → API** e copie:
   - **Project URL**
   - **anon public key** (a chave pública — NÃO a `service_role`)
4. Abra `index.html`, procure por estas duas linhas perto do topo do
   `<script>` (busque por `SUPABASE_URL`):

   ```js
   const SUPABASE_URL = '';
   const SUPABASE_ANON_KEY = '';
   ```

   e preencha com os valores copiados:

   ```js
   const SUPABASE_URL = 'https://seu-projeto.supabase.co';
   const SUPABASE_ANON_KEY = 'sua-chave-anon-publica';
   ```
5. Salve e publique de novo no Vercel.

Pronto — a partir do primeiro pedido enviado, a combinação daquele
copo é registrada na nuvem, e assim que houver dados suficientes o
ranking "🔥 Mais Pedidos" passa a exibir automaticamente as 3
combinações mais pedidas.

## Sobre a segurança da chave

A "anon key" do Supabase é **pública por design** — ela é feita para
rodar no navegador do cliente. A segurança vem do **Row Level
Security (RLS)**, já configurado pelo `supabase_schema.sql`: o
cliente só pode *ler* o ranking e *chamar* a função de incremento —
nunca inserir, editar ou apagar dados diretamente. A chave
`service_role` (essa sim secreta) nunca é usada neste projeto.

## O que foi removido

Frete, cálculo de distância, mapa e geolocalização/GPS não fazem mais
parte do site — o endereço (rua, número, ponto de referência) ainda é
pedido na etapa de localização e vai junto na mensagem do WhatsApp,
mas sem nenhum cálculo automático de valor de entrega.
