class rggen_ral_rwe_rwl_field_callbacks extends uvm_reg_cbs;
  local uvm_reg_field field;
  local bit           enable_mode;
  local string        reg_name;
  local string        field_name;
  local uvm_reg_field mode_field;

  function new(
    string        name,
    uvm_reg_field field,
    bit           enable_mode,
    string        reg_name,
    string        field_name
  );
    super.new(name);
    this.field        = field;
    this.enable_mode  = enable_mode;
    this.reg_name     = reg_name;
    this.field_name   = field_name;
  endfunction

  function void post_predict(
    input uvm_reg_field   fld,
    input uvm_reg_data_t  previous,
    inout uvm_reg_data_t  value,
    input uvm_predict_e   kind,
    input uvm_door_e      path,
    input uvm_reg_map     map
  );
    if ((kind == UVM_PREDICT_WRITE) && !is_writable()) begin
      value = previous;
    end
  endfunction

  local function bit is_writable();
    if ((reg_name.len() > 0) && (field_name.len() > 0)) begin
      lookup_mode_field();
      return (mode_field.value == enable_mode) ? 1 : 0;
    end
    else begin
      return 0;
    end
  endfunction

  local function void lookup_mode_field();
    if (mode_field == null) begin
      uvm_reg       parent_reg;
      uvm_reg_block parent_block;
      uvm_reg       mode_reg;
      parent_reg    = field.get_parent();
      parent_block  = parent_reg.get_parent();
      mode_reg      = parent_block.get_reg_by_name(reg_name);
      mode_field    = mode_reg.get_field_by_name(field_name);
    end
  endfunction
endclass

class rggen_ral_rwe_rwl_field extends rggen_ral_field;
  local static  bit rwe_defined = define_access("RWE");
  local static  bit rwl_defined = define_access("RWL");

  protected rggen_ral_rwe_rwl_field_callbacks callbacks;

  function new(string name, bit enable_mode, string reg_name, string field_name);
    super.new(name);
    callbacks = new("callbacks", this, enable_mode, reg_name, field_name);
  endfunction

  function void configure(
    uvm_reg         parent,
    int unsigned    size,
    int unsigned    lsb_pos,
    string          access,
    bit             volatile,
    uvm_reg_data_t  reset,
    bit             has_reset,
    bit             is_rand,
    bit             individually_accessible
  );
    super.configure(
      parent, size, lsb_pos, access, volatile,
      reset, has_reset, is_rand, individually_accessible
    );
    uvm_reg_field_cb::add(this, callbacks);
  endfunction

  function string get_access(uvm_reg_map map = null);
    uvm_reg parent;

    if (map == uvm_reg_map::backdoor()) begin
      return m_field_access;
    end

    parent  = get_parent();
    case (parent.get_rights(map))
      "RW":     return m_field_access;
      "WO":     return m_field_access;
      "RO":     return "RO";
      default:  return super.get_access(map);
    endcase
  endfunction

  function bit is_known_access(uvm_reg_map map = null);
    case (get_access(map))
      "RWE":    return 1;
      "RWL":    return 1;
      "RO":     return 1;
      default:  return 0;
    endcase
  endfunction
endclass

class rggen_ral_rwe_field #(
  string  REG_NAME    = "",
  string  FIELD_NAME  = ""
) extends rggen_ral_rwe_rwl_field;
  function new(string name);
    super.new(name, 1, REG_NAME, FIELD_NAME);
  endfunction
endclass

class rggen_ral_rwl_field #(
  string  REG_NAME    = "",
  string  FIELD_NAME  = ""
) extends rggen_ral_rwe_rwl_field;
  function new(string name);
    super.new(name, 0, REG_NAME, FIELD_NAME);
  endfunction
endclass
