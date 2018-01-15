#include <razerchroma.h>

void RazerChroma::enable() {
#ifdef _WIN32
    UINT keysNumber = 13;
    UINT VKeys[13] = { 
        // 'F'.charCodeAt(0).toString(16)
        {0x44},             // D
        {0x46},             // F
        {0x47},             // G
        {0x48},             // H
        {0x4F},             // O        
        {VK_OEM_PLUS},      // = (+)
        {VK_OEM_MINUS},     // -        
        {VK_SPACE},         // Spacebar
        {VK_ESCAPE},        // Esc
        {VK_UP},            // Up
        {VK_DOWN},          // Down
        {VK_LEFT},          // Left
        {VK_RIGHT},         // Right
    };

    COLORREF Colors[13] = {
		RGB(140, 40, 170), // D
		RGB(140, 40, 170), // F
		RGB(0, 40, 255), // G
		RGB(0, 40, 255), // H
		RGB(140, 40, 170), // O
		RGB(0, 40, 255), // = (+)
		RGB(0, 40, 255), // -
		RGB(140, 40, 170), // Spacebar
		RGB(140, 40, 170), // Esc
		RGB(140, 40, 170), // Up
		RGB(140, 40, 170), // Down
		RGB(140, 40, 170), // Left
		RGB(140, 40, 170), // Right
    };

    m_ChromaSDKImpl = new CChromaSDKImpl();
    if (m_ChromaSDKImpl->Initialize()) {
        //m_ChromaSDKImpl->ShowKeys(KEYBOARD_DEVICES, keysNumber, VKeys, RGB(140, 40, 170), TRUE);
        m_ChromaSDKImpl->ShowKeysWithCustomCol(KEYBOARD_DEVICES, keysNumber, VKeys, Colors, FALSE); // last arg is "animate"
        // m_ChromaSDKImpl->ResetEffects(KEYBOARD_DEVICES);
    };
#endif
}

void RazerChroma::disable() {
#ifdef _WIN32
if (m_ChromaSDKImpl) {
    // WARNING: after this is done, effects do not get applied on the next enable() even though we use a separate instance
    // that initialized successfully
	m_ChromaSDKImpl->ShowColor(KEYBOARD_DEVICES, RGB(140, 40, 170));
	//m_ChromaSDKImpl->UnInitialize();
	//delete m_ChromaSDKImpl;
}
#endif
}

