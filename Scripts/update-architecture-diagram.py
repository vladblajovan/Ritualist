#!/usr/bin/env python3
"""
Ritualist Architecture Diagram Auto-Updater

This script automatically scans the Ritualist codebase and updates the PlantUML
architecture diagram based on the current code structure.

Usage:
    python3 Scripts/update-architecture-diagram.py

Requirements:
    - Run from the Ritualist project root
    - Python 3.6+
"""

import os
import re
import glob
from pathlib import Path
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass
from datetime import datetime

@dataclass
class Component:
    name: str
    path: str
    type: str  # 'view', 'viewmodel', 'usecase', 'service', 'model', 'repository'
    dependencies: List[str]
    notes: str = ""

class ArchitectureAnalyzer:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.components: Dict[str, Component] = {}
        self.features: Set[str] = set()
        
    def analyze_codebase(self) -> None:
        """Analyze the entire codebase and extract architectural components."""
        print("🔍 Analyzing codebase structure...")
        
        # Scan different layers
        self._scan_features()
        self._scan_domain_layer()
        self._scan_data_layer() 
        self._scan_core_services()
        self._scan_dependency_injection()
        
        print(f"✅ Found {len(self.components)} components across {len(self.features)} features")
    
    def _scan_features(self) -> None:
        """Scan Features/ directory for Views, ViewModels, and feature structure."""
        features_dir = self.project_root / "Ritualist" / "Features"
        
        if not features_dir.exists():
            return
            
        for feature_dir in features_dir.iterdir():
            if feature_dir.is_dir() and not feature_dir.name.startswith('.'):
                feature_name = feature_dir.name
                self.features.add(feature_name)
                
                # Scan Presentation layer
                presentation_dir = feature_dir / "Presentation"
                if presentation_dir.exists():
                    self._scan_presentation_layer(feature_name, presentation_dir)
                    
                # Scan Data layer (if feature has its own data)
                data_dir = feature_dir / "Data"
                if data_dir.exists():
                    self._scan_feature_data_layer(feature_name, data_dir)
    
    def _scan_presentation_layer(self, feature: str, presentation_dir: Path) -> None:
        """Scan presentation layer for Views and ViewModels."""
        swift_files = glob.glob(str(presentation_dir / "**" / "*.swift"), recursive=True)
        
        for file_path in swift_files:
            file_name = Path(file_path).stem
            rel_path = str(Path(file_path).relative_to(self.project_root))
            
            # Parse file content for dependencies
            dependencies = self._extract_dependencies(file_path)
            
            if "View" in file_name and not "Model" in file_name:
                self.components[file_name] = Component(
                    name=file_name,
                    path=rel_path,
                    type='view',
                    dependencies=dependencies,
                    notes=f"{feature} feature view"
                )
            elif "ViewModel" in file_name:
                self.components[file_name] = Component(
                    name=file_name,
                    path=rel_path,
                    type='viewmodel', 
                    dependencies=dependencies,
                    notes=f"{feature} feature view model"
                )
    
    def _scan_domain_layer(self) -> None:
        """Scan Domain/ directory for Entities, UseCases, Repository protocols."""
        domain_dir = self.project_root / "Ritualist" / "Domain"
        
        if not domain_dir.exists():
            return
            
        # Scan Entities
        entities_dir = domain_dir / "Entities"
        if entities_dir.exists():
            for swift_file in entities_dir.glob("*.swift"):
                entities = self._extract_entities_from_file(str(swift_file))
                for entity in entities:
                    self.components[entity] = Component(
                        name=entity,
                        path=str(swift_file.relative_to(self.project_root)),
                        type='entity',
                        dependencies=[],
                        notes="Domain entity"
                    )
        
        # Scan UseCases
        usecases_dir = domain_dir / "UseCases" 
        if usecases_dir.exists():
            for swift_file in usecases_dir.glob("*.swift"):
                usecases = self._extract_usecases_from_file(str(swift_file))
                for usecase in usecases:
                    deps = self._extract_dependencies(str(swift_file))
                    self.components[usecase] = Component(
                        name=usecase,
                        path=str(swift_file.relative_to(self.project_root)),
                        type='usecase',
                        dependencies=deps,
                        notes="Business logic use case"
                    )
        
        # Scan Repository protocols
        repos_dir = domain_dir / "Repositories"
        if repos_dir.exists():
            for swift_file in repos_dir.glob("*.swift"):
                repos = self._extract_repository_protocols(str(swift_file))
                for repo in repos:
                    self.components[repo] = Component(
                        name=repo,
                        path=str(swift_file.relative_to(self.project_root)),
                        type='repository_protocol',
                        dependencies=[],
                        notes="Repository protocol"
                    )
    
    def _scan_data_layer(self) -> None:
        """Scan Data/ directory for SwiftData models and repository implementations."""
        data_dir = self.project_root / "Ritualist" / "Data"
        
        if not data_dir.exists():
            return
            
        # Scan Models
        models_dir = data_dir / "Models"
        if models_dir.exists():
            for swift_file in models_dir.glob("*.swift"):
                models = self._extract_swiftdata_models(str(swift_file))
                for model in models:
                    self.components[model] = Component(
                        name=model,
                        path=str(swift_file.relative_to(self.project_root)),
                        type='swiftdata_model',
                        dependencies=[],
                        notes="SwiftData persistence model"
                    )
        
        # Scan Repository implementations
        repos_dir = data_dir / "Repositories"
        if repos_dir.exists():
            for swift_file in repos_dir.glob("*.swift"):
                repos = self._extract_repository_implementations(str(swift_file))
                for repo in repos:
                    deps = self._extract_dependencies(str(swift_file))
                    self.components[repo] = Component(
                        name=repo,
                        path=str(swift_file.relative_to(self.project_root)),
                        type='repository_impl',
                        dependencies=deps,
                        notes="Repository implementation"
                    )
    
    def _scan_core_services(self) -> None:
        """Scan Core/Services for shared services."""
        services_dir = self.project_root / "Ritualist" / "Core" / "Services"
        
        if not services_dir.exists():
            return
            
        for swift_file in services_dir.glob("*.swift"):
            services = self._extract_services(str(swift_file))
            for service in services:
                deps = self._extract_dependencies(str(swift_file))
                self.components[service] = Component(
                    name=service,
                    path=str(swift_file.relative_to(self.project_root)),
                    type='service',
                    dependencies=deps,
                    notes="Core service"
                )
    
    def _scan_dependency_injection(self) -> None:
        """Scan Extensions/Container+*.swift for DI structure."""
        extensions_dir = self.project_root / "Ritualist" / "Extensions"
        
        if not extensions_dir.exists():
            return
            
        for swift_file in extensions_dir.glob("Container+*.swift"):
            file_name = swift_file.stem
            deps = self._extract_dependencies(str(swift_file))
            self.components[file_name] = Component(
                name=file_name,
                path=str(swift_file.relative_to(self.project_root)),
                type='di_container',
                dependencies=deps,
                notes="Dependency injection container"
            )
    
    def _extract_dependencies(self, file_path: str) -> List[str]:
        """Extract dependencies from a Swift file."""
        dependencies = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Extract imports
            import_pattern = r'^import\s+(\w+)'
            imports = re.findall(import_pattern, content, re.MULTILINE)
            dependencies.extend(imports)
            
            # Extract protocol conformances
            protocol_pattern = r':\s*([A-Z]\w+(?:,\s*[A-Z]\w+)*)'
            protocols = re.findall(protocol_pattern, content)
            for protocol_list in protocols:
                for protocol in protocol_list.split(','):
                    protocol = protocol.strip()
                    if protocol and not protocol in ['ObservableObject', 'Sendable', 'Hashable', 'Equatable']:
                        dependencies.append(protocol)
            
            # Extract initializer dependencies
            init_pattern = r'init\([^)]*(\w+):\s*([A-Z]\w+)'
            init_deps = re.findall(init_pattern, content)
            for _, dep_type in init_deps:
                dependencies.append(dep_type)
                
        except Exception as e:
            print(f"⚠️ Warning: Could not parse {file_path}: {e}")
        
        return list(set(dependencies))  # Remove duplicates
    
    def _extract_entities_from_file(self, file_path: str) -> List[str]:
        """Extract entity names from Domain entities file."""
        entities = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for public struct/class definitions
            entity_pattern = r'public\s+(?:struct|class)\s+(\w+)'
            entities = re.findall(entity_pattern, content)
        except Exception as e:
            print(f"⚠️ Warning: Could not parse entities from {file_path}: {e}")
        
        return entities
    
    def _extract_usecases_from_file(self, file_path: str) -> List[str]:
        """Extract UseCase class names."""
        usecases = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for UseCase classes/protocols
            usecase_pattern = r'(?:public\s+)?(?:final\s+)?(?:class|protocol)\s+(\w*(?:UseCase|UC))'
            usecases = re.findall(usecase_pattern, content)
            
            # Also look for classes ending with UseCase pattern
            class_pattern = r'public\s+final\s+class\s+(\w+):'
            classes = re.findall(class_pattern, content)
            usecases.extend([c for c in classes if 'UseCase' in content])
            
        except Exception as e:
            print(f"⚠️ Warning: Could not parse use cases from {file_path}: {e}")
        
        return list(set(usecases))
    
    def _extract_repository_protocols(self, file_path: str) -> List[str]:
        """Extract repository protocol names."""
        repos = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for repository protocols
            repo_pattern = r'public\s+protocol\s+(\w*Repository\w*)'
            repos = re.findall(repo_pattern, content)
            
        except Exception as e:
            print(f"⚠️ Warning: Could not parse repository protocols from {file_path}: {e}")
        
        return repos
    
    def _extract_swiftdata_models(self, file_path: str) -> List[str]:
        """Extract SwiftData model names."""
        models = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for @Model classes
            model_pattern = r'@Model[^{]*?class\s+(\w+)'
            models = re.findall(model_pattern, content, re.DOTALL)
            
        except Exception as e:
            print(f"⚠️ Warning: Could not parse SwiftData models from {file_path}: {e}")
        
        return models
    
    def _extract_repository_implementations(self, file_path: str) -> List[str]:
        """Extract repository implementation names.""" 
        repos = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for repository implementations
            repo_pattern = r'public\s+final\s+class\s+(\w*Repository\w*Impl\w*)'
            repos = re.findall(repo_pattern, content)
            
        except Exception as e:
            print(f"⚠️ Warning: Could not parse repository implementations from {file_path}: {e}")
        
        return repos
    
    def _extract_services(self, file_path: str) -> List[str]:
        """Extract service class names."""
        services = []
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Look for service classes/protocols
            service_pattern = r'public\s+(?:final\s+)?(?:class|protocol)\s+(\w*Service\w*)'
            services = re.findall(service_pattern, content)
            
            # Also look for specific patterns like Manager, Stack
            other_pattern = r'public\s+final\s+class\s+(\w*(?:Manager|Stack))'
            others = re.findall(other_pattern, content)
            services.extend(others)
            
        except Exception as e:
            print(f"⚠️ Warning: Could not parse services from {file_path}: {e}")
        
        return services

class PlantUMLGenerator:
    def __init__(self, components: Dict[str, Component], features: Set[str]):
        self.components = components
        self.features = features
        
    def generate_diagram(self) -> str:
        """Generate the complete PlantUML diagram."""
        diagram = self._generate_header()
        diagram += self._generate_layers()
        diagram += self._generate_relationships()
        diagram += self._generate_notes()
        diagram += self._generate_footer()
        
        return diagram
    
    def _generate_header(self) -> str:
        """Generate PlantUML header."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        return f"""@startuml Ritualist iOS Architecture

!theme aws-orange
skinparam backgroundColor white
skinparam componentStyle rectangle
skinparam packageStyle rectangle

title Ritualist iOS App - Clean Architecture Overview
note top : Auto-generated on {timestamp}

"""

    def _generate_layers(self) -> str:
        """Generate all architectural layers."""
        layers = ""
        
        # Application Layer
        layers += self._generate_application_layer()
        
        # Features Layer  
        layers += self._generate_features_layer()
        
        # Domain Layer
        layers += self._generate_domain_layer()
        
        # Data Layer
        layers += self._generate_data_layer()
        
        # Core Layer
        layers += self._generate_core_layer()
        
        # DI Layer
        layers += self._generate_di_layer()
        
        return layers
    
    def _generate_application_layer(self) -> str:
        """Generate application layer components."""
        layer = """' ==== Application Layer ====
package "Application Layer" as AppLayer {
    component "RitualistApp" as RitualistApp
    component "RootTabView" as RootTabView
    component "AppDelegate" as AppDelegate
}

"""
        return layer
    
    def _generate_features_layer(self) -> str:
        """Generate features layer with discovered features."""
        layer = """' ==== Features Layer ====
package "Features Layer" as FeaturesLayer {
"""
        
        for feature in sorted(self.features):
            layer += f"""    package "{feature} Feature" as {feature}Feature {{
"""
            
            # Find views and viewmodels for this feature
            feature_views = [c for c in self.components.values() 
                           if c.type == 'view' and feature.lower() in c.notes.lower()]
            feature_viewmodels = [c for c in self.components.values()
                                if c.type == 'viewmodel' and feature.lower() in c.notes.lower()]
            
            for view in feature_views:
                layer += f"        component \"{view.name}\" as {view.name}\n"
            for vm in feature_viewmodels:
                layer += f"        component \"{vm.name}\" as {vm.name}\n"
                
            layer += "    }\n\n"
        
        layer += "}\n\n"
        return layer
    
    def _generate_domain_layer(self) -> str:
        """Generate domain layer with discovered components."""
        layer = """' ==== Domain Layer ====
package "Domain Layer" as DomainLayer {
    package "Entities" as DomainEntities {
"""
        
        # Add discovered entities
        entities = [c for c in self.components.values() if c.type == 'entity']
        for entity in entities:
            layer += f"        component \"{entity.name}\" as {entity.name}Entity\n"
        
        layer += """    }
    
    package "Use Cases" as UseCases {
"""
        
        # Add discovered use cases
        usecases = [c for c in self.components.values() if c.type == 'usecase']
        for usecase in usecases:
            layer += f"        component \"{usecase.name}\" as {usecase.name}\n"
        
        layer += """    }
    
    package "Repository Protocols" as RepoProtocols {
"""
        
        # Add repository protocols
        repo_protocols = [c for c in self.components.values() if c.type == 'repository_protocol']
        for repo in repo_protocols:
            layer += f"        interface \"{repo.name}\" as I{repo.name}\n"
        
        layer += """    }
}

"""
        return layer
    
    def _generate_data_layer(self) -> str:
        """Generate data layer with SwiftData models."""
        layer = """' ==== Data Layer ====
package "Data Layer" as DataLayer {
    package "SwiftData Models" as SDModels {
"""
        
        # Add SwiftData models
        models = [c for c in self.components.values() if c.type == 'swiftdata_model']
        for model in models:
            layer += f"        component \"{model.name}\" as {model.name}\n"
        
        layer += """    }
    
    package "Repository Implementations" as RepoImpl {
"""
        
        # Add repository implementations
        repo_impls = [c for c in self.components.values() if c.type == 'repository_impl']
        for repo in repo_impls:
            layer += f"        component \"{repo.name}\" as {repo.name}\n"
        
        layer += """    }
    
    component "SwiftDataStack" as SwiftDataStack
}

"""
        return layer
    
    def _generate_core_layer(self) -> str:
        """Generate core services layer."""
        layer = """' ==== Core Layer ====
package "Core Layer" as CoreLayer {
    package "Services" as Services {
"""
        
        # Add discovered services
        services = [c for c in self.components.values() if c.type == 'service']
        for service in services:
            layer += f"        component \"{service.name}\" as {service.name}\n"
        
        layer += """    }
}

"""
        return layer
    
    def _generate_di_layer(self) -> str:
        """Generate dependency injection layer."""
        layer = """' ==== Dependency Injection ====
package "Dependency Injection" as DILayer {
    component "Container (FactoryKit)" as Container
    
    package "Container Extensions" as ContainerExt {
"""
        
        # Add DI container extensions
        di_containers = [c for c in self.components.values() if c.type == 'di_container']
        for container in di_containers:
            layer += f"        component \"{container.name}\" as {container.name}\n"
        
        layer += """    }
}

"""
        return layer
    
    def _generate_relationships(self) -> str:
        """Generate relationships between components."""
        relationships = """' ===== RELATIONSHIPS =====

"""
        
        # Add key architectural relationships
        relationships += """' MVVM Pattern
"""
        
        # Generate View -> ViewModel relationships
        views = [c for c in self.components.values() if c.type == 'view']
        viewmodels = [c for c in self.components.values() if c.type == 'viewmodel']
        
        for view in views:
            # Find matching ViewModel
            view_base = view.name.replace('View', '')
            matching_vm = next((vm for vm in viewmodels if vm.name.startswith(view_base)), None)
            if matching_vm:
                relationships += f"{view.name} --> {matching_vm.name} : observes\n"
        
        relationships += """
' Repository Pattern
"""
        
        # Generate Repository protocol -> implementation relationships
        repo_protocols = [c for c in self.components.values() if c.type == 'repository_protocol']
        repo_impls = [c for c in self.components.values() if c.type == 'repository_impl']
        
        for protocol in repo_protocols:
            # Find matching implementation
            matching_impl = next((impl for impl in repo_impls 
                                if protocol.name.replace('Repository', '') in impl.name), None)
            if matching_impl:
                relationships += f"{matching_impl.name} .up.|> I{protocol.name} : implements\n"
        
        # Key security relationship
        relationships += """
' Security Layer
PaywallService --> SecureSubscriptionService : validates purchases

"""
        
        return relationships
    
    def _generate_notes(self) -> str:
        """Generate architectural notes."""
        return """' Architectural Notes
note top of DomainLayer : **Domain Layer**\\n- Pure business logic\\n- No external dependencies\\n- Repository protocols only

note top of DataLayer : **Data Layer**\\n- SwiftData persistence\\n- Entity ↔ Model mapping\\n- Repository implementations

note top of CoreLayer : **Core Layer**\\n- Shared services\\n- Security validation\\n- Feature gating

"""
    
    def _generate_footer(self) -> str:
        """Generate PlantUML footer."""
        return """@enduml"""

def main():
    """Main function to update the architecture diagram."""
    project_root = os.getcwd()
    
    print("🏗️ Ritualist Architecture Diagram Auto-Updater")
    print("=" * 50)
    
    # Analyze codebase
    analyzer = ArchitectureAnalyzer(project_root)
    analyzer.analyze_codebase()
    
    # Generate PlantUML
    generator = PlantUMLGenerator(analyzer.components, analyzer.features)
    diagram_content = generator.generate_diagram()
    
    # Write to file
    output_path = Path(project_root) / "ritualist-architecture.puml"
    
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(diagram_content)
        
        print(f"✅ Architecture diagram updated: {output_path}")
        print(f"📊 Components analyzed: {len(analyzer.components)}")
        print(f"🎯 Features discovered: {', '.join(sorted(analyzer.features))}")
        print("\n💡 Next steps:")
        print("   1. Open the .puml file in VSCode with PlantUML extension")
        print("   2. Preview with Cmd+Shift+P → 'PlantUML: Preview Current Diagram'")
        print("   3. Export with Cmd+Shift+P → 'PlantUML: Export Current Diagram'")
        
    except Exception as e:
        print(f"❌ Error writing diagram: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())