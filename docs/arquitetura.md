# Documento de Arquitetura de Software – RHOS (RH Operation System)
## Projeto Integrado 2026 | P.I-2026-RH-OS | Desenvolvido em Flutter/Dart

---

## 1. Mapeamento de Arquitetura

### 1.1 Padrão Adotado — Clean Architecture

O projeto RH-OS adota **Clean Architecture** com separação explícita em três camadas principais, garantindo independência entre regras de negócio, lógica de aplicação e infraestrutura (Firebase, SQLite). Cada camada se comunica exclusivamente via contratos abstratos (interfaces Dart), nunca por referências concretas cruzadas.

| Camada | Responsabilidade | Tecnologia Principal | Diretório |
|---|---|---|---|
| **Presentation** | UI, widgets, navegação, estado local | Flutter + Riverpod | `lib/presentation/` |
| **Domain** | Entidades, casos de uso, interfaces de repositório | Dart puro | `lib/domain/` |
| **Data** | Implementações concretas, DAOs, parsers, Firebase | Firebase + sqflite | `lib/data/` |
| **Core** | Tema, constantes, utilitários, DI | get_it, Riverpod | `lib/core/` |

### 1.2 Fluxo de Comunicação entre Camadas

A comunicação segue a **Regra da Dependência** do Clean Architecture: dependências apontam sempre de fora para dentro (Presentation → Domain ← Data). Nenhuma camada interna conhece detalhes da camada externa.

```
Presentation (Flutter Widgets + Riverpod Providers)
        │
        ▼  chama via getIt<ICasoDeUso>().executar()
Domain (Casos de Uso + Interfaces)
        │
        ▼  resolve em tempo de execução via get_it
Data (Repositórios Firestore/SQLite + DAOs + Parsers)
        │
        ▼  Firebase SDK / sqflite
Infraestrutura (Cloud Firestore / Firebase Auth / SQLite local)
```

### 1.3 Gerenciamento de Estado — Riverpod

O estado global é gerenciado com Riverpod (`flutter_riverpod` + `riverpod_annotation`). Cada funcionalidade tem um Provider dedicado, evitando acoplamento entre telas. O `ProviderScope` envolve todo o app no `main.dart`.

- `AsyncNotifierProvider` — operações assíncronas com banco (listar candidatos, vagas)
- `StateNotifierProvider` — estado local de formulários e filtros
- `Provider` simples — acesso a serviços via get_it (leitura apenas)

### 1.4 Navegação — go_router

A navegação declarativa usa `go_router` com **redirect guards** que verificam o perfil do usuário autenticado no Firebase Auth. Cada rota tem proteção por perfil: `admin`, `recrutador`, `candidato`, `visualizador`.

```dart
redirect: (context, state) {
  final uid    = prefs.getString('usuario_uid');
  final perfil = prefs.getString('usuario_perfil');
  if (uid == null) return '/login';
  if (state.fullPath == '/admin' && perfil != 'admin') return '/home';
  return null;
}
```

---

## 2. Princípios de Engenharia

| Princípio | Aplicação no Projeto | Exemplo Real |
|---|---|---|
| **SRP** | Cada classe tem uma responsabilidade única | `CandidatoDao` — só acessa SQLite; `ExtratorDados` — só parseia regex |
| **OCP** | Interfaces permitem novas implementações sem alterar o domínio | `ICandidatoRepositorio` implementado por SQLite e Firestore independentemente |
| **LSP** | Implementações substituem interfaces sem quebrar contratos | `CandidatoRepositorioFirestore` substitui `CandidatoRepositorioImpl` com mesma assinatura |
| **ISP** | Interfaces separadas por entidade | `IUsuarioRepositorio`, `ICandidatoRepositorio`, `IVagaRepositorio` — sem interface monolítica |
| **DIP** | Camada domain depende de abstrações | Casos de uso recebem `IRepositorio` via construtor, não implementações concretas |
| **DRY** | Widgets reutilizáveis para padrões visuais | `RhosAppBar`, `CampoPerfilTile`, `AvatarIniciais` usados em todas as telas |
| **Repository Pattern** | Abstração do acesso a dados por entidade | `IVagaRepositorio` → `VagaRepositorioFirestore` / `VagaRepositorioImpl` |
| **Singleton** | Instância única para serviços globais | `BancoHelper.instance`, `FirebaseAuthService` via get_it singleton |
| **Injeção de Dependência** | get_it como service locator | `getIt<ICandidatoRepositorio>()`, `getIt<ListarCandidatos>()` |
| **Factory Method** | Entidades com `fromMap` factory constructor | `Candidato.fromMap(doc.data())`, `Vaga.fromMap(map)` |

### 2.1 Exemplo — Repository Pattern

```dart
// domain/repositorios/i_candidato_repositorio.dart
abstract class ICandidatoRepositorio {
  Future<int> salvar(Candidato candidato);
  Future<List<Candidato>> listarTodos();
  Future<void> deletar(int id);
}

// data/repositorios/candidato_repositorio_firestore.dart
class CandidatoRepositorioFirestore implements ICandidatoRepositorio {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<List<Candidato>> listarTodos() async {
    final snap = await _db.collection('candidatos').get();
    return snap.docs.map((d) {
      return Candidato.fromMap({...d.data(), 'idStr': d.id});
    }).toList();
  }
}
```

### 2.2 Exemplo — Injeção de Dependência (get_it)

```dart
// core/di/injecao.dart
Future<void> configurarDependencias() async {
  getIt.registerLazySingleton<ICandidatoRepositorio>(
    () => CandidatoRepositorioFirestore(),
  );
  getIt.registerLazySingleton(
    () => ListarCandidatos(getIt<ICandidatoRepositorio>()),
  );
}
```

---

## 3. Integração Firebase

### 3.1 Autenticação — Firebase Auth

A autenticação é gerenciada pelo **Firebase Authentication** com provedor Email/Senha. O fluxo substitui a autenticação SHA-256 local por tokens JWT gerenciados pelo Firebase SDK.

- **Login:** `FirebaseAuth.signInWithEmailAndPassword` → token JWT gerado automaticamente
- **Sessão:** `uid` e `perfil` persistidos em `SharedPreferences` após autenticação
- **Guard:** `go_router` verifica `'usuario_uid'` em SharedPreferences a cada navegação
- **Logout:** `FirebaseAuth.signOut` + limpeza de SharedPreferences

### 3.2 Persistência — Cloud Firestore

O Firestore é o banco de dados principal em nuvem. A migração do SQLite ocorre em partes progressivas.

| Coleção | Entidade | Status | Campos Principais |
|---|---|---|---|
| `candidatos` | Candidato | ✅ Migrado | nome, email, cpf, endereço, resumo, idStr |
| `vagas` | Vaga | ✅ Migrado | titulo, status, habilidades_desejadas, idStr |
| `candidaturas` | Candidatura | ✅ Migrado | candidatoIdStr, vagaIdStr, score, status |
| `comentarios` | Comentario | ⏳ Pendente | candidaturaId, autor, texto |
| `notificacoes` | Notificacao | ⏳ Pendente | titulo, mensagem, lida |

### 3.3 Reatividade — Streams vs Futures

| Operação | Abordagem | Justificativa |
|---|---|---|
| Listar candidatos | `Future` (`get()`) | Lista sob demanda, sem necessidade de tempo real |
| Estado de autenticação | `Stream` (`authStateChanges()`) | Reativo a login/logout em tempo real |
| Ranking de candidatos | `Future` + ordenação local | Cálculo de score é síncrono pós-fetch |
| Status de candidatura | `Future` (`update()`) | Atualização pontual pelo recrutador |

### 3.4 Regras de Segurança

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time
        < timestamp.date(2026, 8, 11);
    }
  }
}
```

### 3.5 Pipeline OCR / IA — Fase 2

```
Arquivo selecionado (PDF ou imagem)
       │
       ▼
PdfParser detecta se PDF tem texto selecionável
       ├── SIM ──▶ ExtratorDados (regex, fase 1)
       └── NÃO ──▶ OcrService.extrairTextoDeImagem(bytes)
                          │
                          ▼
               Gemini 2.5 Flash Vision API
               Prompt estruturado → JSON do currículo
                          │
                          ▼
               Campos preenchidos automaticamente
```

---

## 4. Referência de Diagramas

Os diagramas PlantUML estão disponíveis em `docs/diagramas/`:

| Arquivo | Tipo | Descrição |
|---|---|---|
| `UC01-sequencia.puml` | Sequência | Login via Firebase Auth |
| `UC02-sequencia.puml` | Sequência | Upload e extração de currículo |
| `UC01-atividade.puml` | Atividade | Fluxo de atividades do login |
| `UC02-atividade.puml` | Atividade | Fluxo de atividades do upload |
| `componentes.puml` | Componentes | Relação App vs Firebase |
| `classes.puml` | Classes | Entidades e repositórios principais |
| `diagrama-casos-de-uso.puml` | Casos de uso | Atores e casos de uso do sistema |

---

## 5. Auditoria — Documentação vs Implementação

| Requisito | Tipo | Status | Observação |
|---|---|---|---|
| Clean Architecture | RNF07 | ✅ Conforme | lib/ com core/data/domain/presentation |
| Firebase Auth | RNF03 | ✅ Conforme | Email/Senha + uid em SharedPreferences |
| Banco de dados | RNF04 | 🔄 Em migração | SQLite → Firestore (partes 1–7) |
| Riverpod (estado) | RNF08 | ✅ Conforme | Riverpod com @riverpod annotations |
| OCR / IA | RF02 | ⏳ Fase 2 | Placeholder OcrService — Gemini 2.5 Flash |
| Score de candidatos | RF04 | ✅ Conforme | Algoritmo local (hab.60% + idiomas20% + form.20%) |
| Status do candidato | RF05 | ✅ Conforme | Entidade Candidatura com status |
| Controle de acesso | RF08 | ✅ Além do doc. | 4 perfis: admin/recrutador/candidato/visualizador |
| Gestão de vagas | RF09 | ✅ Conforme | TelaCriarVaga + VagaRepositorioFirestore |
| Deduplicação CPF/email | RN01 | ⏳ Fase 6 | buscarPorCpf + buscarPorEmail planejados |
| Relatórios PDF | RF11 | ⏳ Fase futura | Dashboard com fl_chart implementado |
