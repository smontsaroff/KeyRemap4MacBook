#include "bridge.h"
#include "pqrs/vector.hpp"
#include "pqrs/xml_compiler.hpp"

namespace pqrs {
  xml_compiler::remapclasses_initialize_vector::remapclasses_initialize_vector(void)
  {
    clear();
  }

  void
  xml_compiler::remapclasses_initialize_vector::clear(void)
  {
    data_.resize(2);
    data_[INDEX_OF_FORMAT_VERSION] = BRIDGE_REMAPCLASS_INITIALIZE_VECTOR_FORMAT_VERSION;
    data_[INDEX_OF_CONFIG_COUNT] = 0;

    is_config_index_added_.clear();

    max_config_index_ = 0;
    freezed_ = false;
  }

  const std::vector<uint32_t>&
  xml_compiler::remapclasses_initialize_vector::get(void) const
  {
    if (! freezed_) {
      throw xml_compiler_logic_error("remapclasses_initialize_vector is not freezed.");
    }
    return data_;
  }

  uint32_t
  xml_compiler::remapclasses_initialize_vector::get_config_count(void) const
  {
    if (! freezed_) {
      throw xml_compiler_logic_error("remapclasses_initialize_vector is not freezed.");
    }
    return data_[INDEX_OF_CONFIG_COUNT];
  }

  void
  xml_compiler::remapclasses_initialize_vector::add(const std::vector<uint32_t>& v,
                                                    uint32_t config_index,
                                                    const std::string& raw_identifier)
  {
    if (freezed_) {
      throw xml_compiler_logic_error("remapclasses_initialize_vector is freezed.");
    }
    if (is_config_index_added_.find(config_index) != is_config_index_added_.end()) {
      throw xml_compiler_runtime_error(boost::format("Duplicated identifier:\n"
                                                     "\n"
                                                     "<identifier>%1%</identifier>") %
                                       raw_identifier);
    }

    // size
    data_.push_back(v.size() + 1); // +1 == config_index
    // config_index
    data_.push_back(config_index);
    // data
    pqrs::vector::push_back(data_, v);

    ++(data_[INDEX_OF_CONFIG_COUNT]);

    if (config_index > max_config_index_) {
      max_config_index_ = config_index;
    }
    is_config_index_added_[config_index] = true;
  }

  void
  xml_compiler::remapclasses_initialize_vector::freeze(void)
  {
    if (freezed_) {
      throw xml_compiler_logic_error("remapclasses_initialize_vector is already freezed.");
    }

    for (uint32_t i = 0; i < max_config_index_; ++i) {
      if (is_config_index_added_.find(i) == is_config_index_added_.end()) {
        std::vector<uint32_t> v;
        add(v, i, "");
      }
    }

    freezed_ = true;
  }
}
