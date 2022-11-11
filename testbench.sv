// Code your testbench here
// or browse Examples

import uvm_pkg::*;
`include "uvm_macros.svh"


class dff_sequence_item extends uvm_sequence_item;
  
  rand bit D;
  bit Q;
  
  function new(string name="dff_sequence_item");
    super.new(name);
  endfunction
  
    `uvm_object_utils_begin(dff_sequence_item)
    `uvm_field_int(D,UVM_ALL_ON)
    `uvm_field_int(Q,UVM_ALL_ON)
    `uvm_object_utils_end
  
  constraint d_cs{D dist{1:=50,0:=50};}
  
endclass





class dff_squence extends uvm_sequence#(dff_sequence_item);
  `uvm_object_utils(dff_squence);
  dff_sequence_item trans;
  
  function new(string name="dff_squence");
    super.new(name);
  endfunction
  
  virtual task body();
   
   repeat(10)
     
    begin
      `uvm_info(get_type_name(),"New transaction::::",UVM_LOW);
     
    trans=dff_sequence_item::type_id::create("trans");
    
    wait_for_grant();
    
    trans.randomize();
    
    send_request(trans);
    
    wait_for_item_done();
    end
    
  endtask
    
  endclass
    
  
    
    
    
    
 class dff_squencer extends uvm_sequencer#(dff_sequence_item);
   `uvm_component_utils(dff_squencer);

   
   function new(string name="dff_squencer",uvm_component parent);
     super.new(name,parent);
   endfunction
   

endclass
    
    

    
    

class dff_driver extends uvm_driver#(dff_sequence_item);
  
  `uvm_component_utils(dff_driver);
  virtual IF if1;
  dff_sequence_item trans;
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    uvm_config_db#(virtual IF)::get(this,"","if1",if1);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever
        begin
        seq_item_port.get_next_item(trans);
        trans.print();
          
        drive();

        seq_item_port.item_done();
        end
   endtask
  
  virtual task drive();
    if1.D=trans.D;
    @(posedge if1.clk);
    #3;
  endtask
  
endclass
    
    

    
    
class dff_monitor extends uvm_monitor;
  `uvm_component_utils(dff_monitor);
  
  virtual IF if1;
  
  dff_sequence_item trans_trf;
  dff_sequence_item trans_ref;

  uvm_analysis_port#(dff_sequence_item) mon_port_trf;// Analysis port
  uvm_analysis_port#(dff_sequence_item) mon_port_ref;// Analysis port

  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    uvm_config_db#(virtual IF)::get(this,"","if1",if1);
    trans_trf=dff_sequence_item::type_id::create("trans_trf");
    trans_ref=dff_sequence_item::type_id::create("trans_ref");
    
    mon_port_trf=new("mon_port_trf",this);
    mon_port_ref=new("mon_port_ref",this);
 endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        trans_ref.D=if1.D;/// This is ref data input which helps for comparision in scoreboard
        
        trans_trf.D=if1.D; ///This is transfer obj, in and out of DUT 
        @(posedge if1.clk);
        #2;
        trans_trf.Q=if1.Q;
        
        trans_trf.print();
        trans_ref.print();
      
        mon_port_trf.write(trans_trf);
        mon_port_ref.write(trans_ref);
        
      end
  endtask
    
endclass
    
 
   
    
    
    
class dff_agent extends uvm_component;
  `uvm_component_utils(dff_agent)
   dff_squencer sqncr;
   dff_driver  drv;
   dff_monitor mon;
  
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqncr=dff_squencer::type_id::create("sqncr",this);
    drv=dff_driver::type_id::create("drv",this);
    mon=dff_monitor::type_id::create("mon",this);
  endfunction
    
        
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqncr.seq_item_export);
  endfunction
  
endclass

    
 
    
    
    

      
    class dff_scoreboard extends uvm_scoreboard;
      `uvm_component_utils(dff_scoreboard)
       dff_sequence_item tr_ref;
       dff_sequence_item tr_trf;
      
       uvm_analysis_export#(dff_sequence_item) scr_export_ref;
       uvm_analysis_export#(dff_sequence_item) scr_export_trf;
      
       uvm_tlm_analysis_fifo#(dff_sequence_item) fifo_ref;
       uvm_tlm_analysis_fifo#(dff_sequence_item) fifo_trf;
      
       function new(string name,uvm_component parent);
        super.new(name,parent);
       endfunction
      
      
       function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scr_export_ref=new("scr_export_ref",this); //Analysis export 
        scr_export_trf=new("scr_export_trf",this); //Analysis export 
        
        fifo_ref=new("fifo_ref",this);
        fifo_trf=new("fifo_trf",this);
        
       endfunction
  
      
      function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        scr_export_ref.connect(fifo_ref.analysis_export);
        scr_export_trf.connect(fifo_trf.analysis_export);
      endfunction
      
      
        
    virtual task run_phase(uvm_phase phase);

      forever
          begin
              fifo_ref.get(tr_ref);
              fifo_trf.get(tr_trf);

                      tr_ref.print();
                      tr_trf.print();



              if(tr_ref.D==tr_trf.Q)
                begin
                  $display("DATA MATCHED");
                end
              else
                begin
                $display("DATA MISMATCHED");
                end
            
          end
      endtask
      
      
    endclass
    
    
      
      
  
    
    
    

class dff_environment extends uvm_env;
  `uvm_component_utils(dff_environment)

  dff_agent agnt;
  dff_scoreboard scr;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt=dff_agent::type_id::create("agnt",this);
    scr=dff_scoreboard::type_id::create("scr",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agnt.mon.mon_port_ref.connect(scr.scr_export_ref);
    agnt.mon.mon_port_trf.connect(scr.scr_export_trf);
  endfunction

endclass

    
  
    
    
    
class dff_test extends uvm_test;
  `uvm_component_utils(dff_test)

  dff_squence squnc;
  dff_environment env;

  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    squnc=dff_squence::type_id::create("squnc");
    env=dff_environment::type_id::create("env",this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    squnc.start(env.agnt.sqncr);
    phase.drop_objection(this);
  endtask


endclass
    
    
    
    
    
    
    
    
    
module top;

  IF if1();

  D_ff dff1(.clk(if1.clk),.reset(if1.reset),.D(if1.D),.Q(if1.Q));

  always #5 if1.clk = ~if1.clk;

  initial
    begin
      if1.clk=0;
      uvm_config_db#(virtual IF)::set(null,"*","if1",if1);
      run_test("dff_test");
    end


endmodule


            
            
              
              
        
      
    
    
  
  
    
    
      
     
    
    
   
   
   
    
    
    
    
    
    
    
    


































  

  
  