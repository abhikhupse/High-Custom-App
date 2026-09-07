#pragma once

// Small compatibility layer for the two ATL conversion helpers used by
// flutter_secure_storage_windows. Keeping these conversions here avoids
// requiring Visual Studio's optional ATL workload.

#include <string>

class CA2W {
 public:
  explicit CA2W(const char* value) {
    if (value == nullptr) return;
    const int size = MultiByteToWideChar(CP_UTF8, 0, value, -1, nullptr, 0);
    if (size <= 0) return;
    storage_.resize(static_cast<size_t>(size));
    MultiByteToWideChar(CP_UTF8, 0, value, -1, storage_.data(), size);
    storage_.pop_back();
    m_psz = storage_.data();
  }

  wchar_t* m_psz = nullptr;

 private:
  std::wstring storage_;
};

class CW2A {
 public:
  explicit CW2A(const wchar_t* value) {
    if (value == nullptr) return;
    const int size = WideCharToMultiByte(
        CP_UTF8, 0, value, -1, nullptr, 0, nullptr, nullptr);
    if (size <= 0) return;
    storage_.resize(static_cast<size_t>(size));
    WideCharToMultiByte(CP_UTF8, 0, value, -1, storage_.data(), size, nullptr,
                        nullptr);
    storage_.pop_back();
  }

  operator const char*() const { return storage_.c_str(); }

 private:
  std::string storage_;
};
