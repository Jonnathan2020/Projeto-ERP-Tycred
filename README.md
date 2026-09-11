# Projeto ERP — Tycred

## 1. Caracterização da empresa

### 1.1 Segmento

A Tycred atua no segmento de serviços financeiros (fintech de crédito), especificamente na vertical de concessão e recuperação de crédito pessoal para pessoa física, também conhecida no mercado como empréstimo pessoal não consignado.

Dentro desse segmento, a empresa opera nas duas pontas do ciclo de crédito:

- Originação/Concessão — análise, aprovação e formalização de novos contratos de empréstimo, atuando como credora direta (não é intermediária de banco nem correspondente bancário).
- Recuperação de Crédito — gestão ativa da carteira em atraso, com cobrança, renegociação e autoatendimento para reduzir a inadimplência sem depender só de ação judicial.

### 1.2 Serviços oferecidos

A Tycred oferece empréstimo pessoal para clientes pessoa física, com pagamento parcelado em prestações fixas (Tabela Price).

Além da concessão do crédito em si, a empresa oferece:

- Simulação e contratação de empréstimo com geração de contrato digital e assinatura eletrônica
- Pagamento das parcelas via Pix ou boleto
- Canal de autoatendimento (portal do devedor) para consulta de extrato e renegociação de dívidas em atraso
- Renegociação e refinanciamento para clientes inadimplentes, com condições facilitadas para recuperação do crédito concedido.

### 1.3 Principais clientes

Pessoas físicas maiores de idade, com CPF regularizado, que buscam crédito pessoal para finalidades diversas (quitação de dívidas, emergências financeiras, compra de bens e produtos).

O perfil típico inclui muitos clientes que têm dificuldade de acesso a crédito nos bancos tradicionais (score baixo, renda informal, pouco histórico bancário), o que torna a análise de crédito interna da Tycred um processo especialmente importante — é ela quem decide o risco que os bancos tradicionais evitam assumir.

### 1.4 Principais setores

- Atendimento Comercial/Concessão — recebe e processa as solicitações de empréstimo
- Análise de Crédito — avalia o risco e aprova ou reprova propostas, com apoio de score
- Cobrança e Recuperação — atua sobre contratos em atraso, via atendentes humanos e o portal de autoatendimento
- Atendimento ao Cliente — suporte geral, dúvidas sobre contrato e pagamento
- Financeiro/Controladoria — acompanha o caixa, fatura recebimentos, pagamentos e inadimplência da carteira
- Jurídico/Compliance — cuida da validade dos contratos e da conformidade com regras de crédito ao consumidor e códigos do CDC (ex: limites de juros e multa do CDC).

### 1.5 Como funciona a operação atual

Atualmente, boa parte do processo da Tycred é feito de forma manual ou semiautomatizada.

As propostas de crédito chegam por WhatsApp, telefone ou um formulário simples, e a análise de crédito é feita manualmente por um analista, consultando informações do cliente de forma avulsa.

Os contratos são gerados em modelos de documento fixos e assinados fisicamente ou por e-mail, sem trilha de auditoria estruturada.

O controle das parcelas e do saldo devedor é feito em planilhas de Excel, atualizadas manualmente pelo setor financeiro — o que gera atrasos na identificação de inadimplência.

A cobrança também é manual: os atendentes ligam ou mandam mensagem para os devedores seguindo uma lista, sem critério automatizado de priorização, e não há nenhum canal de autoatendimento para o cliente negociar sozinho.

Pagamentos via Pix ou boleto não são reconhecidos automaticamente — alguém do financeiro precisa checar o extrato bancário e dar baixa manual na planilha.

### 1.6 Informações importantes para o negócio

- Dados cadastrais do cliente (CPF, nome, contato, renda declarada)
- Dados do contrato de empréstimo (valor, taxa, número de parcelas, datas de vencimento)
- Status de cada parcela (paga, pendente, em atraso, pagamento parcial) e valor atualizado com multa/mora
- Histórico de pagamentos e de tentativas de contato/cobrança
- Histórico de renegociações e acordos firmados
- Informações de análise de crédito (score, motivo de aprovação/reprovação)
- Controle de inadimplentes
- Registros para monitoramento de demanda, custos, lucros e porcentagem de recuperação
- DRE
- Registro de auditoria de alterações em valores de dívida (rastreabilidade).

---

## 2. Justificativa da escolha

### 2.1 Processos e problemas de organização

A Tycred possui diversos processos interdependentes, como captação de propostas, análise de crédito, formalização de contratos, cobrança, inadimplência e renegociação. Atualmente, parte dessas atividades depende de controles manuais, como planilhas, WhatsApp e conferência de pagamentos, o que pode gerar erros, duplicidade e informações desatualizadas.

### 2.2 Integração entre setores

A empresa possui diferentes setores, como Comercial, Análise de Crédito, Cobrança, Atendimento, Financeiro e Jurídico, que dependem das mesmas informações. A falta de integração dificulta o acesso ao histórico do cliente, situação das parcelas e pagamentos realizados. Um banco de dados centralizado permitiria compartilhar essas informações de forma organizada e confiável.

### 2.3 Viabilidade do ERP

A Tycred apresenta características que justificam a aplicação de um ERP financeiro, como controle de contratos e parcelas, cálculo de juros e multas, acompanhamento de pagamentos, gerenciamento de inadimplência e diferentes níveis de acesso. Além disso, empresas reais do setor, como a QI Tech, demonstram que soluções tecnológicas semelhantes já possuem aplicação no mercado financeiro.

A Tycred foi escolhida por apresentar processos complexos, problemas reais de organização de dados e necessidade de integração, tornando-se um caso adequado para a modelagem de um ERP financeiro.

---

## 3. Processos de negócio

### 3.1 Concessão e Análise de Crédito

Cliente → Solicita Empréstimo → Análise de Crédito → Contrato → Assinatura

**Como é realizado manualmente hoje:**
O cliente entra em contato por WhatsApp, telefone ou formulário. O atendente coleta os dados pessoais e financeiros e registra manualmente, possivelmente numa planilha. O CPF é consultado à parte para verificar inadimplência, e o analista consulta score e histórico financeiro em sistemas externos, separadamente. São verificadas renda mensal, empréstimos e financiamentos existentes, e o analista calcula manualmente se a parcela pretendida cabe no limite de comprometimento de renda (regra de aproximadamente 30% do salário). Com base nisso, decide por aprovar ou reprovar e se aprovado, calcula as condições do empréstimo, elabora o contrato e envia pro cliente assinar.

- **Quem participa?** Cliente, Atendente e Analista de crédito.
- **O que inicia o processo?** O cliente entra em contato pedindo o empréstimo.
- **O que acontece?** Coleta manual de dados, consultas externas separadas (CPF, score), cálculo manual do comprometimento de renda, decisão do analista, elaboração do contrato.
- **Qual informação é gerada?** Dados do cliente, resultado das consultas externas, cálculo de comprometimento de renda, decisão (aprovado/reprovado), contrato.
- **Qual é o resultado?** Contrato elaborado e enviado para assinatura (ou reprovação registrada).

### 3.2 Pagamento e Baixa de Parcela

Cliente → Realiza Pagamento → Conferência do Financeiro → Baixa da Parcela → Atualização do Saldo

**Como é realizado manualmente hoje:**
O cliente recebe os dados para pagar via Pix ou boleto e realiza o pagamento. O setor financeiro consulta o extrato bancário ou sistema de pagamentos, identifica manualmente a qual cliente e parcela aquele valor pertence, registra o pagamento numa planilha (ou sistema separado) e atualiza o saldo devedor. Se o pagamento não for identificado de imediato, a parcela continua aparecendo como pendente até uma nova conferência.

- **Quem participa?** Cliente e funcionário do setor financeiro.
- **O que inicia o processo?** O cliente realiza o pagamento de uma parcela.
- **O que acontece?** Conferência manual do extrato, identificação do cliente/parcela, registro manual, atualização do saldo devedor.
- **Qual informação é gerada?** Registro do pagamento, novo status da parcela, saldo devedor atualizado.
- **Qual é o resultado?** Parcela marcada como paga (com atraso na identificação, se o pagamento não for reconhecido de imediato).

### 3.3 Cobrança de Parcela em Atraso

Parcela Vencida → Cálculo de Multa/Mora → Lista de Cobrança → Contato do Atendente → Registro da Tratativa

**Como é realizado manualmente hoje:**
O funcionário consulta uma planilha ou lista de parcelas, identifica quais estão próximas do vencimento ou já atrasadas, e verifica manualmente se o pagamento foi feito. Se não foi pago, calcula ou verifica o valor atualizado com multa e mora, inclui o cliente numa lista de cobrança, e o atendente entra em contato por telefone ou WhatsApp. O resultado do contato é registrado manualmente; se o cliente promete pagar, o funcionário precisa acompanhar isso depois; se não há pagamento, novas tentativas são feitas.

- **Quem participa?** Funcionário/Atendente e Devedor.
- **O que inicia o processo?** Uma parcela vence sem pagamento identificado.
- **O que acontece?** Consulta manual de planilha, cálculo de multa/mora, inclusão em lista de cobrança, contato telefônico, registro manual do resultado.
- **Qual informação é gerada?** Lista de devedores em atraso, valor atualizado da dívida, histórico de contatos, promessas de pagamento.
- **Qual é o resultado?** Cliente contatado, com uma tentativa de cobrança registrada — pode virar pagamento, promessa ou nova tentativa futura.

### 3.4 Renegociação de Dívida

Cliente → Solicita Renegociação → Cálculo de Condições → Acordo → Novo Contrato

**Como é realizado manualmente hoje:**
O atendente identifica o valor que o cliente deve, consulta as parcelas vencidas e os encargos, e calcula manualmente diferentes possibilidades de negociação (valor, quantidade de parcelas, vencimentos). Apresenta as opções ao cliente, que escolhe ou negocia novas condições. O atendente registra o acordo numa planilha ou documento, elabora um novo contrato/acordo, atualiza manualmente o contrato original indicando que foi renegociado, e cadastra as novas parcelas separadamente.

- **Quem participa?** Atendente e Devedor.
- **O que inicia o processo?** O devedor (ou o próprio atendente durante uma cobrança) decide negociar a dívida em atraso.
- **O que acontece?** Cálculo manual de opções de negociação, apresentação ao cliente, registro do acordo, elaboração de novo contrato, atualização manual do contrato original.
- **Qual informação é gerada?** Opções de negociação calculadas, acordo firmado, novo contrato, vínculo (manual) com o contrato original.
- **Qual é o resultado?** Um novo contrato/acordo, com o original marcado manualmente como renegociado.

### 3.5 Autoatendimento do Devedor

Cliente → Solicita Informação → Atendente Consulta → Repasse Manual → Encaminhamento

**Como seria sem ERP:**
Esse processo é praticamente inexistente ou muito limitado sem uma plataforma integrada. O cliente entra em contato com a empresa para saber quanto deve; o atendente consulta manualmente planilhas e outros sistemas e informa parcelas e valores ao cliente. Se ele quiser pagar, o funcionário envia os dados de pagamento manualmente; se quiser renegociar, precisa aguardar a atuação de um atendente. Tudo que acontece no atendimento é registrado manualmente.

- **Quem participa?** Cliente e Atendente (obrigatoriamente — não há autonomia do cliente hoje).
- **O que inicia o processo?** O cliente entra em contato querendo saber sua situação de dívida.
- **O que acontece?** Consulta manual pelo atendente, repasse de informação ao cliente, encaminhamento manual para pagamento ou negociação.
- **Qual informação é gerada?** Registro manual do atendimento e da solicitação do cliente.
- **Qual é o resultado?** Cliente informado ou encaminhado, mas sempre dependendo de um atendente humano.

### 3.6 Monitoria de Qualidade do Atendimento

Atendimento Realizado → Seleção pelo Analista → Avaliação por Critérios → Nota → Registro em Planilha

**Como é realizado manualmente hoje:**
O analista de qualidade seleciona alguns atendimentos realizados, consulta conversas, ligações ou registros armazenados em locais diferentes, e analisa manualmente a forma como o atendente conduziu o atendimento, usando critérios definidos pela empresa. Atribui uma nota de qualidade e registra a avaliação numa planilha; se necessário, compara avaliações entre diferentes atendentes.

- **Quem participa?** Analista de qualidade e Atendente avaliado.
- **O que inicia o processo?** A seleção de um atendimento já realizado para revisão.
- **O que acontece?** Consulta manual do registro do atendimento, análise segundo critérios da empresa, atribuição de nota.
- **Qual informação é gerada?** Nota de qualidade, registro da avaliação.
- **Qual é o resultado?** Indicador de qualidade do atendimento, registrado isoladamente em planilha.

---

## 4. Problemas identificados

**Onde existe retrabalho?**
Sim — no Financeiro, que precisa checar extrato bancário e depois digitar o pagamento numa planilha; e na Cobrança, que recalcula manualmente o valor de multa/mora que poderia vir pronto.

**Existem informações duplicadas?**
Sim — dados do cliente podem aparecer em mais de um lugar (planilha de propostas, planilha de contratos, anotações do atendente), sem um cadastro único de referência.

**Existem informações perdidas?**
Sim — o histórico de tentativas de contato de cobrança fica descentralizado (anotações soltas, WhatsApp, memória do atendente), podendo se perder se o atendente sair da empresa ou trocar de canal.

**A empresa utiliza planilhas?**
Sim, de forma intensa — controle de parcelas e saldo devedor, registro de pagamentos, lista de cobrança, registro de acordos de renegociação e avaliações de monitoria de qualidade são todos feitos em planilhas separadas.

**Existem controles manuais?**
Sim — análise de crédito, cálculo de comprometimento de renda, conferência de pagamento, cálculo de multa/mora, cálculo de opções de renegociação e avaliação de qualidade do atendimento são todos feitos manualmente.

**Os setores compartilham informações?**
Não de forma estruturada — Análise de Crédito, Financeiro e Cobrança trabalham cada um com sua própria planilha, sem uma base de dados comum.

**É difícil encontrar informações?**
Sim — o histórico do cliente está espalhado entre proposta, contrato, planilha de pagamento e anotações de cobrança, exigindo consultar vários lugares para ter a visão completa.

**Existem erros de cadastro?**
Sim, potencialmente — a digitação manual de dados do cliente (na concessão) e dos pagamentos (na baixa) cria risco de erro de digitação e duplicidade de CPF.

**É difícil acompanhar devedores ou atendentes?**
Sim — não existe priorização automática de quem cobrar primeiro, nem indicador consolidado do desempenho dos atendentes.

**Existem problemas para gerar relatórios?**
Sim — os dados financeiros, de cobrança e de qualidade estão em planilhas separadas, impedindo um relatório gerencial único sem consolidação manual prévia.

### 4.1 Concessão e Análise de Crédito

| Problema | Consequência |
|---|---|
| Dados espalhados em diferentes lugares | Dificuldade para ter uma visão única do cliente e da proposta |
| Digitação manual dos dados do cliente | Maior chance de erro de cadastro e retrabalho de correção |
| Maior possibilidade de erros | Decisões de crédito tomadas com base em informação incorreta |
| Consultas realizadas separadamente (CPF, score, renda) | Processo de análise mais lento e sujeito a esquecimento de alguma verificação |
| Dificuldade para recuperar o histórico do cliente | Analista pode repetir avaliação de risco já feita antes |
| Ausência de visão centralizada da proposta | Falta de padronização entre propostas analisadas por pessoas diferentes |

### 4.2 Pagamento e Baixa de Parcela

| Problema | Consequência |
|---|---|
| Conferência manual dos pagamentos | Demora entre o pagamento do cliente e o reconhecimento pela empresa |
| Possibilidade de baixa incorreta ou duplicada | Cliente cobrado por uma parcela já paga, gerando desgaste e reclamação |
| Informações desatualizadas | Setor de cobrança pode agir sobre uma dívida que já foi quitada |
| Trabalho repetitivo para o financeiro | Uso de tempo da equipe em tarefa que poderia ser automática |
| Dificuldade para saber a situação real da carteira em tempo real | Decisões gerenciais tomadas com dado defasado |

### 4.3 Cobrança de Parcela em Atraso

| Problema | Consequência |
|---|---|
| Ausência de priorização automática dos clientes | Atendente pode focar em devedor de menor risco enquanto outro mais crítico fica sem contato |
| Controle por planilhas/listas | Risco de a lista ficar desatualizada ou divergente entre atendentes |
| Risco de esquecer uma cobrança | Aumento do tempo de atraso e da dificuldade de recuperação do valor |
| Histórico de contatos descentralizado | Perda de continuidade no acompanhamento do devedor |
| Cálculos manuais (multa e mora) | Inconsistência no valor cobrado do cliente em atraso |
| Dificuldade para acompanhar promessas de pagamento | Promessa feita pelo cliente pode ser esquecida e nunca cobrada de volta |

### 4.4 Renegociação de Dívida

| Problema | Consequência |
|---|---|
| Cálculos manuais das opções de negociação | Risco de oferecer condição fora da política da empresa |
| Risco de erros nos valores | Prejuízo financeiro ou insatisfação do cliente por valor incorreto |
| Dificuldade para vincular o novo acordo à dívida original | Risco de perder a rastreabilidade da dívida e cobrar duas vezes |
| Informações espalhadas em documentos e planilhas | Dificuldade de auditoria e de conferência do acordo firmado |
| Falta de histórico completo da renegociação | Impossibilidade de saber quantas vezes um cliente já renegociou |

### 4.5 Autoatendimento do Devedor

| Problema | Consequência |
|---|---|
| Dependência constante de atendimento humano | Sobrecarga da equipe mesmo para dúvidas simples |
| Maior tempo de resposta | Cliente insatisfeito por não conseguir resolver algo simples com rapidez |
| Informações não disponíveis ao cliente em tempo real | Cliente sem controle sobre a própria situação financeira |
| Maior volume de trabalho para a equipe de cobrança | Menos tempo disponível para casos mais complexos de negociação |
| Impossibilidade de negociação automatizada | Empresa perde oportunidade de recuperar dívidas pequenas sem custo de atendimento |

> **Observação:** diferente dos demais processos, o Portal de Autoatendimento não é
> a automação de algo que já existe hoje — é uma solução nova proposta pelo ERP,
> já que esse processo praticamente não existe de forma independente na Tycred.

### 4.6 Monitoria de Qualidade do Atendimento

| Problema | Consequência |
|---|---|
| Processo demorado | Poucos atendimentos avaliados dentro de um período |
| Avaliações manuais | Julgamento sujeito à subjetividade de quem avalia |
| Dificuldade para analisar grande quantidade de atendimentos | Amostragem pequena, não representativa da equipe toda |
| Resultados armazenados em planilhas | Dado isolado, sem cruzamento com outros indicadores |
| Dificuldade para gerar indicadores consolidados | Gestor sem visão clara do desempenho da equipe de atendimento |

---

## 5. Requisitos funcionais

*(a ser preenchido nas próximas etapas do projeto)*

## 6. Requisitos não funcionais

*(a ser preenchido nas próximas etapas do projeto)*

## 7. Regras de negócio

*(a ser preenchido nas próximas etapas do projeto)*

## 8. Restrições e políticas organizacionais

*(a ser preenchido nas próximas etapas do projeto)*

## 9. Fluxogramas

*(a ser preenchido nas próximas etapas do projeto)*

## 10. Entidades

*(a ser preenchido nas próximas etapas do projeto)*

## 11. Atributos

*(a ser preenchido nas próximas etapas do projeto)*

## 12. Relacionamentos

*(a ser preenchido nas próximas etapas do projeto)*

## 13. Cardinalidades

*(a ser preenchido nas próximas etapas do projeto)*

## 14. Dicionário de dados conceitual

*(a ser preenchido nas próximas etapas do projeto)*

## 15. DER

*(a ser preenchido nas próximas etapas do projeto)*

## 16. Justificativas técnicas

*(a ser preenchido nas próximas etapas do projeto)*

## 17. Conclusão

*(a ser preenchido nas próximas etapas do projeto)*
