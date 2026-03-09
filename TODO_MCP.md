# Material Maker MCP Integration — Fork Todo

> Development tasks for integrating MCP server into the Material Maker fork.
> Repository: derekrhiggins/material-maker (fork of RodZill4/material-maker)

---

### Phase F1 — Addon Integration

- [x] **F1.** Create `addons/material_maker_mcp/` directory in MM source tree
- [x] **F2.** Copy and adapt `addon.gd` — fix main_window reference to use `mm_globals.main_window`, add async dispatch support
- [x] **F3.** Copy command handlers (`commands/scene.gd`, `graph.gd`, `parameters.gd`, `export.gd`, `utils.gd`)
- [x] **F4.** Register autoload in `project.godot`: `mm_mcp="*res://addons/material_maker_mcp/addon.gd"`
- [ ] **F5.** Verify TCP server starts automatically on MM launch — test with `nc -z localhost 9002`
- [ ] **F6.** Test basic ping/pong round-trip from Python MCP server to forked MM

---

### Phase F2 — Wire Up Real MM APIs

> The command handlers were written against assumed APIs. Now we validate and fix against real MM internals.

- [x] **F7.** Audit `scene.gd` — rewritten to use `graph_edit.save_path`, `need_save`, `save_file()`, `do_load_project()`, `new_material()`, `.ptex` extension
- [x] **F8.** Audit `graph.gd` — rewritten to use `graph_edit.create_nodes()` (async), `graph.remove_generator()`, `graph.connect_children()`, `graph.disconnect_children()`
- [x] **F9.** Audit `graph.gd` — `get_graph_info` reads `graph.get_children()` and `graph.connections` directly
- [x] **F10.** Audit `graph.gd` — `list_available_nodes` uses `mm_loader.get_generator_list()` / `NodeLibraryManager`
- [x] **F11.** Audit `parameters.gd` — uses `get_parameter()`/`set_parameter()` with correct type coercion (`"boolean"` not `"bool"`)
- [x] **F12.** Audit `export.gd` — rewritten to use `render_output()` for individual maps and `export_material(prefix, profile)` for engine export
- [x] **F13.** All API mismatches fixed — handlers rewritten against real MM source code

---

### Phase F3 — Preview / Visual Feedback

- [ ] **F14.** Implement `get_preview_image` command in GDScript — capture a node's 2D texture preview as PNG bytes
- [ ] **F15.** Implement `get_3d_preview` command — capture the 3D material preview viewport as PNG bytes
- [ ] **F16.** Add `get_preview_image` tool to Python MCP server — return base64 PNG as MCP image content
- [ ] **F17.** Add `get_3d_preview` tool to Python MCP server
- [ ] **F18.** Test preview capture round-trip — verify Claude Code can receive and interpret the images

---

### Phase F4 — End-to-End Testing

- [ ] **F19.** Create a test script that builds a complete material (e.g. procedural brick) via MCP commands
- [ ] **F20.** Verify full workflow: new_project → create nodes → connect → set params → preview → export
- [ ] **F21.** Test with Claude Code as the MCP client — have Claude create a material from a text description
- [ ] **F22.** Stress test: rapid sequential commands, large graphs (50+ nodes), parameter sweeps
- [ ] **F23.** Test error paths: invalid node types, bad connections, missing parameters

---

### Phase F5 — Polish & Upstream Sync

- [ ] **F24.** Add MCP server status indicator to MM UI (optional panel or status bar text)
- [ ] **F25.** Document how to build and run the forked MM with MCP support
- [ ] **F26.** Set up upstream sync workflow — periodically merge from RodZill4/material-maker master
- [ ] **F27.** Create release builds (Windows, Linux, macOS) of the MCP-enabled MM fork
- [ ] **F28.** Update material-maker-mcp README to point to the fork for the MM side (instead of manual addon install)

---

### Notes

- MM's main window is accessed via `mm_globals.main_window` (the `mm_globals` autoload)
- Node library is at `main_window.node_library_manager`
- Current graph is accessed through the projects panel: `main_window.projects_panel`
- MM uses `node_factory.gd` for creating nodes programmatically
- Export pipeline is in `addons/material_maker/engine/`
