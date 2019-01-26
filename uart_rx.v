//The reciver is able to recieve 8 bits of data serially, with 1 stop bit, 1 start bit and there is no parity bit present.
//When the reciever completes recieving all the data o_rx_dv will be driven high representing transfer is complete and data is successfully recieved. 
//setting up CLKs_PER_BIT:
//CLKS_PER_BIT= frequency of i_clock/frequency of uart(baud rate)
//For 10 MHZ clock and 115200 of baud rate, the CLS_PER_BIT is 10 x 10 ^6/115200 = 87

`timescale 1ns/10ps
module UART_RX
  #(parameter CLKS_PER_BIT = 87)
  (
   input        i_Clock, //clock signal
   input        i_RX_Serial, //data that comes serially from the tx to rx
   output       o_RX_DV,//This signal is high for the clock cycle when the data is recived is recived successfully and this acts as a status bit
   output [7:0] o_RX_Byte//8 bit data as the output comes out in the parallel form from the rx_module
   );
     //intializing the parametres //s=states of the rx state machine and the numbering is done to represent that specfic state
   
  parameter IDLE         = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  //defining and intializing all the register(r) values
  reg [7:0] r_Clock_Count = 0;
  reg [2:0] r_Bit_Index   = 0; //8 bits total
  reg [7:0] r_RX_Byte     = 0;
  reg       r_RX_DV       = 0;
  reg [2:0] r_SM_Main     = 0;
  reg  R_RX_DATA_R  =1'b1;
  reg  R_RX_DATA  = 1'b1;
  
   always @ (posedge i_Clock)
    //at the rising edge of the clock 
    //data is recived serially
    begin 
      R_RX_DATA_R <=  i_RX_Serial;
      R_RX_DATA <=  R_RX_DATA_R ;
    end
  
  // A state machine for the reciver can be defined with the specfic states. And so r_sm_main is used which is intialized to 0 which is idle state of state machine.
  
  // Purpose: Control RX state machine
  always @(posedge i_Clock)
  begin
      //FSM state = 000
    case (r_SM_Main)
     //This is the current state of the fsm
      IDLE :
        begin
          r_RX_DV       <= 1'b0;   // this entity is zero as the data is not recived yet
          r_Clock_Count <= 0;  
          r_Bit_Index   <= 0; //idle state representation so these two entities are also zero.
          
          if (i_RX_Serial == 1'b0)     // Start bit detected
           //start bit is detected as these bit goes high to low after which the data bits appears
            r_SM_Main <= RX_START_BIT;
             //the Fsm goes to the next state
          else
            r_SM_Main <= IDLE;
             //the Fsm stays to same state
        end
        
        //FSM state = 001
      // Check middle of start bit to make sure it's still low
      RX_START_BIT :
      //CLKS_PER_BIT as counted previously is 87.
         // The 0 or 1 in data is detected when clock_count is greater then half of CLKS_PER_BIT
        begin
          if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
          //the value comes out to be clock_count == 44
          begin
            if (i_RX_Serial == 1'b0)
             //this triggering condition is used to jump to next state
            begin
            //found in middle //shifting to next state
              r_Clock_Count <= 0;  
              r_SM_Main     <= RX_DATA_BITS;
            end
            else
              r_SM_Main <= IDLE;
              //jump directly to state = 000
              //executing outer loop
          end
          else
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            //Here the clock count has yet not reached to half of CLKS_PER_BIT and so start_bit state jumps to itself state till the above condition is satisfied.
            r_SM_Main     <= RX_START_BIT;
            //stays on the same state till clock_count reaches CLK_PER_BITS==44.
          end
        end // case: RX_START_BIT
      
      //FSM = 010
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      RX_DATA_BITS :
        begin
        //waiting for clock_cycles == CLKS_PER_BIT -1 to sample all the serial data
          if (r_Clock_Count < CLKS_PER_BIT-1)
          // if r_clock_count < 86
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_DATA_BITS;
            //Stays on the same state till condition is met i.e clock_count = 86 
          end
          else
          begin
            r_Clock_Count          <= 0;
            r_RX_Byte[r_Bit_Index] <= i_RX_Serial;
            //The above state is used to check if all the bits are recieved.
            // Check if we have received all bits
            if (r_Bit_Index < 7)
            begin
            //if all the data is not recieved
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= RX_DATA_BITS;
            end
            else
            begin
            //FSM stays on the same state till all the data is not recived.
              r_Bit_Index <= 0;
              r_SM_Main   <= RX_STOP_BIT;
            end
          end
        end // case: RX_DATA_BITS
      
      //FSM state = 011
      // Receive Stop bit.  Stop bit = 1
      RX_STOP_BIT :
        begin
         //wait for clock_cycles to reach CLKS_PER_BIT-1 for stopbit to finish
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
     	    r_SM_Main     <= RX_STOP_BIT;
          end
          else
          begin
       	    r_RX_DV       <= 1'b1;
       	    //as all the data is successfully recived this bit will remain high for a clock cycle
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
          end
        end // case: RX_STOP_BIT
      
       //FSM state = 100
      // Stay here 1 clock
      CLEANUP :
        begin
          r_SM_Main <= IDLE;
          r_RX_DV   <= 1'b0;
           //Defining the cleanup state here the above command is 0 as all the data is recieved.
        end
      
       //defining the default state
      default :
        r_SM_Main <= IDLE;
      
    endcase
  end    
  
  assign o_RX_DV   = r_RX_DV;
  assign o_RX_Byte = r_RX_Byte;
  //hardwired connections of internal and external signals
  
endmodule // UART_RX
