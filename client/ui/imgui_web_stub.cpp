// Emscripten-only ImGui stand-in. Part of an AI-generated browser experiment (Cursor).
// Desktop builds do not compile this file.
#include "imgui_manager.h"
#include "imgui_window_system.h"
#include <memory>

class CImGuiBackend {};

CImGuiWindowSystem::CImGuiWindowSystem() = default;
void CImGuiWindowSystem::AddWindow(IImGuiWindow *) {}
void CImGuiWindowSystem::LinkWindows() {}
void CImGuiWindowSystem::Initialize() {}
void CImGuiWindowSystem::VidInitialize() {}
void CImGuiWindowSystem::Terminate() {}
void CImGuiWindowSystem::NewFrame() {}
bool CImGuiWindowSystem::KeyInput(bool, int, const char *) { return false; }
bool CImGuiWindowSystem::CursorRequired() { return false; }

CImGuiManager &g_ImGuiManager = CImGuiManager::GetInstance();

CImGuiManager &CImGuiManager::GetInstance()
{
	static CImGuiManager instance;
	return instance;
}

void CImGuiManager::Initialize() {}
void CImGuiManager::VidInitialize() {}
void CImGuiManager::Terminate() {}
void CImGuiManager::NewFrame() {}
bool CImGuiManager::KeyInput(bool, int, const char *) { return false; }
void CImGuiManager::TextInputCallback(const char *) {}

CImGuiManager::CImGuiManager() : m_pBackend(std::make_unique<CImGuiBackend>()) {}
CImGuiManager::~CImGuiManager() = default;

void CImGuiManager::LoadFonts() {}
void CImGuiManager::ApplyStyles() {}
void CImGuiManager::UpdateMouseState() {}
void CImGuiManager::UpdateCursorState() {}
void CImGuiManager::UpdateTextInputState() {}
void CImGuiManager::UpdateKeyModifiers() {}
void CImGuiManager::HandleKeyInput(bool, int) {}
bool CImGuiManager::HandleMouseInput(bool, int) { return false; }
void CImGuiManager::SetupConfig() {}
void CImGuiManager::SetupKeyboardMapping() {}
void CImGuiManager::SetupCursorMapping() {}
void CImGuiManager::CheckVguiApiPresence() {}
const char *CImGuiManager::GetClipboardText(void *) { return ""; }
void CImGuiManager::SetClipboardText(void *, const char *) {}
