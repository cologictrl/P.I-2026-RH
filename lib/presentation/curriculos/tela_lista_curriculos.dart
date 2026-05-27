import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rh_os/core/constantes/app_rotas.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/di/injecao.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/domain/casos_de_uso/candidatos/listar_candidatos.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/presentation/widgets/candidato_card.dart';
import 'package:rh_os/presentation/widgets/rhos_app_bar.dart';

class TelaListaCurriculos extends ConsumerStatefulWidget {
  const TelaListaCurriculos({super.key});

  @override
  ConsumerState<TelaListaCurriculos> createState() =>
      _TelaListaCurriculosState();
}

class _TelaListaCurriculosState extends ConsumerState<TelaListaCurriculos> {
  final _busca = TextEditingController();
  List<Candidato> _todos = [];
  List<Candidato> _filtrados = [];
  String _criterio = 'nome';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
    _busca.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  // D4: usa caso de uso ListarCandidatos em vez do repositório diretamente.
  Future<void> _carregar() async {
    try {
      final lista = await getIt<ListarCandidatos>().executar();
      if (mounted) {
        setState(() {
          _todos = lista;
          _filtrados = lista;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('[TelaListaCurriculos] Erro ao carregar: $e');
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _filtrar() {
    final termo = _busca.text.toLowerCase();
    setState(() {
      _filtrados = _todos.where((c) {
        if (_criterio == 'cidade') {
          return (c.cidade ?? '').toLowerCase().contains(termo);
        }
        return c.nome.toLowerCase().contains(termo);
      }).toList();
    });
  }

  Future<void> _excluirCandidato(
      BuildContext context, Candidato candidato) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Deseja excluir o currículo de '
          '${candidato.nome}?\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // D1/D4: usa idStr como identificador principal; repositório tipado.
      if (candidato.idStr != null && candidato.idStr!.isNotEmpty) {
        await getIt<ICandidatoRepositorio>().deletarPorIdStr(candidato.idStr!);
        debugPrint('[Lista] Excluído do Firestore: ${candidato.idStr}');
      } else {
        debugPrint(
            '[Lista] idStr ausente — exclusão ignorada para ${candidato.nome}');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currículo excluído com sucesso'),
            backgroundColor: AppCores.primaria,
          ),
        );
        _carregar();
      }
    } catch (e) {
      debugPrint('[ExcluirCandidato] Erro: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPrincipal,
      appBar: const RhosAppBarInterna(
        icone: Icons.description_outlined,
        titulo: AppStrings.tituloCurriculos,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                const Text(AppStrings.pesquisarPor,
                    style: TextStyle(
                        fontSize: 13, color: AppCores.textoSecundario)),
                _chipFiltro('Nome', 'nome'),
                _chipFiltro('Cidade', 'cidade'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _busca,
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppCores.fundoInput,
                hintText: AppStrings.pesquisarCurriculo,
                prefixIcon: Icon(Icons.search, color: AppCores.textoSecundario),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(
                    child: CircularProgressIndicator(color: AppCores.primaria))
                : _filtrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: AppCores.textoSecundario),
                            SizedBox(height: 12),
                            Text(AppStrings.nenhumCurriculo,
                                style:
                                    TextStyle(color: AppCores.textoSecundario)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          itemCount: _filtrados.length,
                          itemBuilder: (_, i) {
                            final c = _filtrados[i];
                            return CandidatoCard(
                              nome: c.nome,
                              dataNascimento: c.dataNascimento,
                              cidade: c.cidade,
                              estado: c.estado,
                              email: c.email,
                              telefone: c.telefone,
                              rua: c.logradouro,
                              numero: c.numero,
                              bairro: c.bairro,
                              aoExcluir: () => _excluirCandidato(context, c),
                              aoEditar: () => context.push(AppRotas.perfil),
                              aoVerCompleto: (() {
                                final id = c.idStr ?? c.id?.toString() ?? '';
                                if (id.isEmpty) return null;
                                return () => context
                                    .push(AppRotas.curriculoCompletoId(id));
                              })(),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String label, String valor) {
    final sel = _criterio == valor;
    return GestureDetector(
      onTap: () {
        setState(() => _criterio = valor);
        _filtrar();
      },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? AppCores.primaria : AppCores.fundoInput,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: sel ? AppCores.textoClaro : AppCores.textoPrincipal,
            )),
      ),
    );
  }
}
