require 'test_helper'


# Umlaut::ControllerBehavior#create_collection
#
# Loads service definitions into a Collection object, based on services configuration
# and current &umlaut.service_group param. Tests. 
class CreateCollectionTest <  ActiveSupport::TestCase
  setup :set_custom_service_store

  def set_custom_service_store
    dummy = {"type" => "DummyService", "priority" => 3}

    # This would normally be loaded as YAML, we're going to set it
    # directly. 
    service_declerations = {
      "default" => {
        "services" => {
          "default_a"         => dummy.clone,
          "default_b"         => dummy.clone,
          "default_disabled"  => dummy.clone.merge("disabled" => true)
        }
      },

      "group1" => {
        "services" => {
          "group1_a"        => dummy.clone,
          "group1_b"        => dummy.clone,
          "group1_disabled"  => dummy.clone.merge("disabled" => true)
        }
      },      

      "group2" => {
        "services" => {
          "group2_a"        => dummy.clone,
          "group2_b"        => dummy.clone,
          "group2_disabled"  => dummy.clone.merge("disabled" => true)
        }
      }
    }

    @service_store = ServiceStore.new
    @service_store.config = service_declerations    
  end

  def test_basic
    service_list = Collection.determine_services({}, @service_store)

    # default group services
    assert_include service_list.keys, "default_a"
    assert_include service_list.keys, "default_b"

    # but not the disabled one
    assert_not_include service_list.keys, "default_disabled"
  
    # No group1 or group2
    assert_nil service_list.keys.find {|key| key.start_with? "group1"}
    assert_nil service_list.keys.find {|key| key.start_with? "group2"}
  end

  def test_add_groups
    service_list = Collection.determine_services({"umlaut.service_group" => "group2,group1"}, @service_store)

    ["default_a", "default_b", "group1_a", "group1_b", "group2_a", "group2_b"].each do |service_id|
      assert_include service_list.keys, service_id
    end

    ["default_disabled", "group1_disabled", "group2_disabled"].each do |service_id|
      assert_not_include service_list.keys, service_id
    end
  end

  def test_add_group_no_default
    service_list = Collection.determine_services({"umlaut.service_group" => "group1,-default"}, @service_store)

    # does not include default ones
    assert_nil service_list.keys.find {|id| id.start_with? "default_"}

    # does include group1 ones
    assert_include service_list.keys, "group1_a"
    assert_include service_list.keys, "group1_b"
  end

  
end