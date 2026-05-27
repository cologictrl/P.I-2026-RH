// Strings centralizadas de UI.

abstract class AppStrings {
  // Globais
  static const String nomeApp = 'RH-OS';
  static const String tagline = 'Gestão inteligente para sua empresa';
  static const String subtituloApp = 'Sistema de Gestão de Recursos Humanos';

  // Autenticacao
  static const String boasVindas = 'Boas - Vindas';
  static const String subtituloLogin = 'Entre com seu usuário e senha';
  static const String labelUsuario = 'Usuário';
  static const String labelSenha = 'Senha';
  static const String botaoEntrar = 'ENTRAR';
  static const String erroLoginInvalido = 'Usuário ou senha inválidos';

  // Navegacao
  static const String navInicio = 'Início';
  static const String navMais = 'Mais';

  // Home
  static const String ola = 'Olá, ';

  // Menu
  static const String menuNotificacoes = 'Notificações';
  static const String menuPerfil = 'Informações do meu perfil';
  static const String menuCurriculos = 'Currículos';
  static const String menuVagas = 'Vagas';
  static const String menuUpload = 'Registrar novo currículo';
  static const String menuGestaoUsuarios = 'Gestão de usuários';

  // Curriculos
  static const String tituloCurriculos = 'Currículos';
  static const String pesquisarCurriculo = 'Pesquisar currículo...';
  static const String pesquisarPor = 'Pesquisar por:';
  static const String porNome = 'Nome';
  static const String porIdade = 'Idade';
  static const String porSexo = 'Sexo';
  static const String infosRapidas = 'Informações rápidas';
  static const String excluirCurriculo = 'Excluir currículo';
  static const String editarCurriculo = 'Editar currículo';
  static const String verCurriculoCompleto = 'Ver currículo completo';
  static const String nenhumCurriculo = 'Nenhum currículo cadastrado ainda';

  // Upload
  static const String tituloUpload = 'Registrar currículo';
  static const String selecioneCurriculo = 'Selecione um currículo';
  static const String formatosAceitos = 'Formatos aceitos: PDF e TXT';
  static const String selecionarArquivo = 'Selecionar arquivo';
  static const String extraindoDados = 'Extraindo dados...';
  static const String confirmarSalvar = 'Confirmar e Salvar';
  static const String naoEncontrado = 'não encontrado';
  static const String curriculoSalvo = 'Currículo salvo com sucesso!';
  static const String erroCurriculo = 'Erro ao salvar currículo';

  // Perfil
  static const String tituloPerfil = 'Informações do meu perfil';
  static const String infoPessoal = 'Informações pessoais';
  static const String dadosConta = 'Dados da conta';
  static const String endereco = 'Endereço';
  static const String labelNome = 'Nome e sobrenome';
  static const String labelCpf = 'Número do CPF';
  static const String labelNomePreferencia = 'Nome de preferência';
  static const String labelEmail = 'E-mail';
  static const String labelTelefone = 'Telefone';
  static const String labelRua = 'Rua';
  static const String labelBairro = 'Bairro';
  static const String labelCidade = 'Cidade - Estado';
  static const String labelCep = 'CEP';
  static const String salvar = 'Salvar';
  static const String campoSalvo = 'Campo atualizado com sucesso!';

  // Vagas
  static const String tituloVagas = 'Vagas';
  static const String criarVaga = 'Criar Vaga';
  static const String chipTodas = 'Todas';
  static const String chipAbertas = 'Abertas';
  static const String chipTriagem = 'Em triagem';
  static const String chipEncerradas = 'Encerradas';
  static const String nenhumaVaga = 'Nenhuma vaga cadastrada ainda';
  static const String labelTitulo = 'Título';
  static const String labelDescricao = 'Descrição';
  static const String labelRequisitos = 'Requisitos';
  static const String labelHabilidades = 'Habilidades desejadas';
  static const String labelIdiomasVaga = 'Idiomas desejados';
  static const String labelFormacaoMinima = 'Formação mínima';
  static const String vagaCriada = 'Vaga criada com sucesso!';

  // Candidaturas
  static const String abaCandidatos = 'Candidatos';
  static const String abaComentarios = 'Comentários';
  static const String aprovar = 'Aprovar';
  static const String reprovar = 'Reprovar';
  static const String emAnalise = 'Em análise';
  static const String enviarComentario = 'Enviar';
  static const String comentarioPlaceholder = 'Adicione um comentário...';
  static const String nenhumCandidato = 'Nenhum candidato inscrito ainda';
  static const String nenhumComentario = 'Nenhum comentário ainda';

  // Dashboard
  static const String tituloDashboard = 'Dashboard';
  static const String totalCandidatos = 'Total candidatos';
  static const String vagasAbertas = 'Vagas abertas';
  static const String aprovados = 'Aprovados';
  static const String emAnaliseLabel = 'Em análise';
  static const String atividadeRecente = 'Atividade recente';
  static const String topHabilidades = 'Top 5 Habilidades';
  static const String distribuicao = 'Distribuição de Status';

  // Admin
  static const String tituloAdmin = 'Gestão de usuários';
  static const String novoUsuario = 'Novo usuário';
  static const String usuarioSalvo = 'Usuário salvo com sucesso!';
  static const String naoDesativarSi =
      'Você não pode desativar seu próprio usuário';
  static const String nenhumUsuario = 'Nenhum usuário cadastrado';

  // Confirmacoes
  static const String confirmarExclusao = 'Confirmar exclusão';
  static const String descricaoExclusaoCurr =
      'Tem certeza que deseja excluir este currículo? Esta ação não pode ser desfeita.';
  static const String cancelar = 'Cancelar';
  static const String excluir = 'Excluir';
  static const String excluido = 'Excluído com sucesso!';

  // Erros
  static const String erroGenerico = 'Ocorreu um erro. Tente novamente.';
  static const String erroEmailInvalido = 'E-mail inválido';
  static const String erroCpfInvalido = 'CPF inválido';
  static const String erroTelInvalido = 'Telefone inválido';
  static const String erroCampoObrig = 'Campo obrigatório';
}
