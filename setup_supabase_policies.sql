-- Script para configurar políticas de segurança no Supabase
-- Execute estes comandos no SQL Editor do seu projeto Supabase

-- 1. Habilitar RLS nas tabelas
ALTER TABLE produtos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pontos ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_venda ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas existentes (se houver)
DROP POLICY IF EXISTS "Permitir tudo para usuários autenticados" ON produtos;
DROP POLICY IF EXISTS "Permitir tudo para usuários autenticados" ON pontos;
DROP POLICY IF EXISTS "Permitir tudo para usuários autenticados" ON vendedores;
DROP POLICY IF EXISTS "Permitir tudo para usuários autenticados" ON vendas;
DROP POLICY IF EXISTS "Permitir tudo para usuários autenticados" ON itens_venda;

-- 3. Criar políticas para permitir acesso completo para usuários autenticados

-- Política para produtos
CREATE POLICY "Permitir tudo para usuários autenticados" ON produtos
FOR ALL USING (auth.role() = 'authenticated');

-- Política para pontos
CREATE POLICY "Permitir tudo para usuários autenticados" ON pontos
FOR ALL USING (auth.role() = 'authenticated');

-- Política para vendedores
CREATE POLICY "Permitir tudo para usuários autenticados" ON vendedores
FOR ALL USING (auth.role() = 'authenticated');

-- Política para vendas
CREATE POLICY "Permitir tudo para usuários autenticados" ON vendas
FOR ALL USING (auth.role() = 'authenticated');

-- Política para itens_venda
CREATE POLICY "Permitir tudo para usuários autenticados" ON itens_venda
FOR ALL USING (auth.role() = 'authenticated');

-- 4. Verificar se as políticas foram criadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('produtos', 'pontos', 'vendedores', 'vendas', 'itens_venda');

-- 5. Verificar se RLS está habilitado
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('produtos', 'pontos', 'vendedores', 'vendas', 'itens_venda');

-- 6. Testar inserção de dados (opcional)
-- INSERT INTO produtos (codigo, nome) VALUES (999, 'Produto Teste RLS');
-- INSERT INTO pontos (nome) VALUES ('Ponto Teste RLS');
-- INSERT INTO vendedores (nome) VALUES ('Vendedor Teste RLS');

-- 7. Verificar dados existentes
SELECT 'produtos' as tabela, count(*) as total FROM produtos
UNION ALL
SELECT 'pontos' as tabela, count(*) as total FROM pontos
UNION ALL
SELECT 'vendedores' as tabela, count(*) as total FROM vendedores
UNION ALL
SELECT 'vendas' as tabela, count(*) as total FROM vendas
UNION ALL
SELECT 'itens_venda' as tabela, count(*) as total FROM itens_venda; 