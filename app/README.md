# 🌸 Meu Ciclo — Gerenciador de Ciclo Menstrual

Aplicativo mobile desenvolvido com **Flutter** e **Supabase** para registro e acompanhamento do ciclo menstrual.

---

## 📱 Funcionalidades

- ✅ Cadastro e login de usuária com e-mail e senha
- ✅ Logout e proteção de telas (apenas usuárias autenticadas acessam o conteúdo)
- ✅ Registrar início e fim da menstruação
- ✅ Registrar duração do ciclo e do período
- ✅ Registrar humor e sintomas por ciclo
- ✅ Adicionar anotações livres
- ✅ Ver histórico de todos os ciclos
- ✅ Editar e excluir registros
- ✅ Previsão da próxima menstruação com base na média dos ciclos
- ✅ Exibição de estatísticas (ciclo médio, período médio)

---

## 🛠️ Tecnologias

| Tecnologia | Função |
|---|---|
| Flutter | Interface do aplicativo (mobile/web) |
| Dart | Linguagem de programação |
| Supabase Auth | Autenticação (cadastro, login, logout) |
| Supabase Database | Armazenamento dos dados (PostgreSQL) |

---

## 📁 Estrutura de Arquivos

```
lib/
├── main.dart                  # Ponto de entrada; inicializa Supabase e define tema
│
├── models/
│   └── cycle_entry.dart       # Modelo de dados de um ciclo (campos, toMap, fromMap)
│
├── services/
│   ├── auth_service.dart      # Login, cadastro, logout, dados do usuário
│   └── database_service.dart  # CRUD completo dos ciclos + estatísticas
│
├── screens/
│   ├── login_screen.dart      # Tela de login (formulário + navegação)
│   ├── register_screen.dart   # Tela de cadastro
│   ├── home_screen.dart       # Tela principal: lista, estatísticas, previsão
│   └── form_screen.dart       # Tela de criar/editar um ciclo
│
└── widgets/
    ├── custom_button.dart     # Botão reutilizável (primário e contornado)
    ├── custom_text_field.dart # Campo de texto reutilizável com validação
    └── cycle_card.dart        # Card que exibe um ciclo na lista
```

---

## ▶️ Como executar o projeto

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado
- Conta no [Supabase](https://supabase.com) (gratuita)

### Passo 1 — Clonar o repositório
```bash
git clone https://github.com/seu-usuario/ciclo_menstrual.git
cd ciclo_menstrual
```

### Passo 2 — Configurar o Supabase

1. Crie um projeto em [supabase.com](https://supabase.com)
2. Vá em **SQL Editor** e execute o conteúdo do arquivo `supabase_setup.sql`
3. Vá em **Settings → API** e copie a **URL** e a **anon key**
4. Cole os valores em `lib/main.dart`:

```dart
await Supabase.initialize(
  url: 'https://SEU_PROJECT_ID.supabase.co',
  anonKey: 'SUA_ANON_KEY',
);
```

### Passo 3 — Instalar dependências
```bash
flutter pub get
```

### Passo 4 — Executar
```bash
flutter run
```

---

## 🔐 Autenticação

A autenticação usa o **Supabase Auth** com e-mail e senha.

| Ação | Onde |
|---|---|
| Cadastro | `AuthService.signUp()` → `register_screen.dart` |
| Login | `AuthService.signIn()` → `login_screen.dart` |
| Logout | `AuthService.signOut()` → `home_screen.dart` |
| Verificação de sessão | `main.dart` → redireciona para Home ou Login |

As telas de conteúdo só são acessíveis após login. Se o usuário não tiver sessão ativa, é redirecionado para a tela de login.

---

## 🗄️ Banco de Dados

Tabela: `cycle_entries`

| Coluna | Tipo | Descrição |
|---|---|---|
| id | UUID | Identificador único (automático) |
| user_id | UUID | ID da usuária dona do registro |
| start_date | DATE | Data de início da menstruação |
| end_date | DATE | Data de término (opcional) |
| cycle_length | INTEGER | Duração do ciclo em dias |
| period_length | INTEGER | Duração do período em dias |
| mood | TEXT | Humor registrado |
| symptoms | TEXT[] | Lista de sintomas |
| notes | TEXT | Anotações livres |
| created_at | TIMESTAMPTZ | Data de criação do registro |

O **Row Level Security (RLS)** garante que cada usuária acesse apenas seus próprios dados.
