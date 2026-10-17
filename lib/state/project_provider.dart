import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../data/models/project.dart';
import 'connection_provider.dart';

class ProjectState {
  final List<HermesProject> projects;
  final HermesProject? activeProject;
  final bool isLoading;
  final String? error;

  const ProjectState({
    this.projects = const [],
    this.activeProject,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<HermesProject>? projects,
    HermesProject? activeProject,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      activeProject: activeProject ?? this.activeProject,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final Ref _ref;

  ProjectNotifier(this._ref) : super(const ProjectState()) {
    _init();
  }

  void _init() {
    _ref.listen(connectionProvider, (prev, next) {
      if (next.status.isConnected && (prev == null || !prev.status.isConnected)) {
        loadProjects();
      }
    });
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final list = await repo.listProjects();
      final active = list.where((p) => p.isActive).firstOrNull;
      state = state.copyWith(
        projects: list,
        activeProject: active,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setActiveProject(HermesProject? project) async {
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      if (project != null) {
        await repo.setActiveProject(project.id);
        state = state.copyWith(
          activeProject: project,
          projects: state.projects
              .map((p) => p.copyWith(isActive: p.id == project.id))
              .toList(),
        );
      } else {
        await repo.setActiveProject('');
        state = state.copyWith(
          activeProject: null,
          projects: state.projects.map((p) => p.copyWith(isActive: false)).toList(),
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<HermesProject?> createProject(String name, String path) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final project = await repo.createProject(name, path);
      state = state.copyWith(
        projects: [...state.projects, project],
        isLoading: false,
      );
      return project;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier(ref);
});
