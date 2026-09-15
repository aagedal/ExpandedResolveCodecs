#pragma once

#include <memory>

#include "wrapper/plugin_api.h"

using namespace IOPlugin;

//fwd decl
struct x264_t;
struct x264_param_t;
class UISettingsController;

class X264Encoder : public IPluginCodecRef
{
public:
    static const uint8_t s_UUID[];

public:
    X264Encoder();
    ~X264Encoder();

    static StatusCode s_RegisterCodecs(HostListRef* p_pList);
    static StatusCode s_GetEncoderSettings(HostPropertyCollectionRef* p_pValues, HostListRef* p_pSettingsList);

    virtual bool IsNeedNextPass() override
    {
        return (m_IsMultiPass && (m_PassesDone < 2));
    }

    virtual bool IsAcceptingFrame(int64_t p_PTS) override
    {
        if (m_AcceptQueries++ == 0)
        {
            g_Log(logLevelInfo, "X264 Plugin :: First frame acceptance query at PTS %lld",
                  static_cast<long long>(p_PTS));
        }
        // Accept every frame in a single pass and while multipass is active.
        return !m_IsMultiPass || (m_PassesDone < 3);
    }

protected:
    virtual StatusCode DoFlush() override;
    virtual StatusCode DoInit(HostPropertyCollectionRef* p_pProps) override;
    virtual StatusCode DoOpen(HostBufferRef* p_pBuff) override;
    virtual StatusCode DoProcess(HostBufferRef* p_pBuff) override;

private:
    void SetupContext(bool p_IsFinalPass);

private:
    x264_t* m_pContext;
    int m_ColorModel;
    std::unique_ptr<UISettingsController> m_pSettings;
    HostCodecConfigCommon m_CommonProps;

    bool m_IsMultiPass;
    uint32_t m_PassesDone;
    uint64_t m_InputFrames;
    uint64_t m_OutputFrames;
    uint64_t m_AcceptQueries;
    StatusCode m_Error;
};
