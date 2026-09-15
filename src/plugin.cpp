#include "plugin.h"

#include <cstring>

#include "x264_encoder.h"

static const uint8_t pMyUUID[] = { 0x50, 0xf9, 0x75, 0xd8, 0x97, 0xc8, 0x4f, 0x60, 0xbc, 0x89, 0x10, 0xd2, 0xc6, 0x8b, 0x21, 0x52 };

using namespace IOPlugin;

StatusCode g_HandleGetInfo(HostPropertyCollectionRef* p_pProps)
{
    StatusCode err = p_pProps->SetProperty(pIOPropUUID, propTypeUInt8, pMyUUID, 16);
    if (err == errNone)
    {
        const char* name = "Expanded Resolve Codecs x264 PoC";
        err = p_pProps->SetProperty(pIOPropName, propTypeString, name, strlen(name));
    }

    return err;
}

StatusCode g_HandleCreateObj(unsigned char* p_pUUID, ObjectRef* p_ppObj)
{
    if (memcmp(p_pUUID, X264Encoder::s_UUID, 16) == 0)
    {
        *p_ppObj = new X264Encoder();
        return errNone;
    }
    return errUnsupported;
}

StatusCode g_HandlePluginStart()
{
    // perform libs initialization if needed
    return errNone;
}

StatusCode g_HandlePluginTerminate()
{
    return errNone;
}

StatusCode g_ListCodecs(HostListRef* p_pList)
{
    return X264Encoder::s_RegisterCodecs(p_pList);
}

StatusCode g_ListContainers(HostListRef* p_pList)
{
    return errNone;

}

StatusCode g_GetEncoderSettings(unsigned char* p_pUUID, HostPropertyCollectionRef* p_pValues, HostListRef* p_pSettingsList)
{
    if (memcmp(p_pUUID, X264Encoder::s_UUID, 16) == 0)
    {
        return X264Encoder::s_GetEncoderSettings(p_pValues, p_pSettingsList);
    }
    return errNoCodec;
}
