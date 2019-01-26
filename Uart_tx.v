//The transmitter is able to transmit 8 bits of data serially, with 1 stop bit, 1 start bit and there is no parity bit present.
//When the transmitter completes recieving all the data i_tx_dv will be driven high representing transfer is complete and data is successfully recieved. 
//setting up CLKs_PER_BIT:
//CLKS_PER_BIT= frequency of i_clock/frequency of uart(baud rate)
//For 10 MHZ clock and 115200 of baud rate, the CLKS_PER_BIT is 10 x 10 ^6/115200 = 87
`timescale 1ns/10ps
module UART_TX 
  #(parameter CLKS_PER_BIT = 87)
  (
   input       i_Clock, //clock signal
   input       i_TX_DV, 
   input [7:0] i_TX_Byte, //data entering in parallel form, defining vector for 8 bit of data
   output      o_TX_Active, 
   output reg  o_TX_Serial, //data out serially and going to the reciver
   output      o_TX_Done  //When the transmitter is done transmitting the data then this bit is high
   );
 //These are the states of the state machine and there numbering is done
  parameter IDLE         = 3'b000; 
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  //defining registers to store the values
  reg [2:0] r_SM_Main     = 0; //This stores the state of the state machine and is 0 intially i.e idle state
  reg [7:0] r_Clock_Count = 0; //clock count for the transmitter
  reg [2:0] r_Bit_Index   = 0; //This keeps the count for the 8 data bits in 210 fashion 
  reg [7:0] r_TX_Data     = 0; //Transmitting data bit for TX
  reg       r_TX_Done     = 0; //This bit if high indicates that the transmission is completed
  reg       r_TX_Active   = 0; 
    //here all the registers are intiallized to 0 
  always @(posedge i_Clock)
  begin
      //FSM = 000
    case (r_SM_Main)
      IDLE :
        begin
          o_TX_Serial   <= 1'b1;         // Drive Line High for Idle
          //These bits are 0 as FSM is still in the idle state
          r_TX_Done     <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          //As transmitter has yet not transmitted all the 8 bits these above bit are 0
          if (i_TX_DV == 1'b1)
          begin
          //Data transmission has started for the below active bit is high and here the start bit is detected
            r_TX_Active <= 1'b1;
            r_TX_Data   <= i_TX_Byte;
            r_SM_Main   <= TX_START_BIT;
          end
          else
          //if transmission is not started yet then it stays at idle state
            r_SM_Main <= IDLE;
        end // case: IDLE
      
      
      // Send out Start Bit. Start bit = 0
      //Fsm = 001
      TX_START_BIT :
        begin
          o_TX_Serial <= 1'b0;
          //Here serial data communication has still not started
          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_START_BIT;
          end
          else
          begin
            r_Clock_Count <= 0;
            r_SM_Main     <= TX_DATA_BITS;
          end
        end // case: TX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
      //Fsm =010
      TX_DATA_BITS :
      //here data transmission starts
        begin
          o_TX_Serial <= r_TX_Data[r_Bit_Index];
          //the tx serial bit takes the input serially out from tx data bit and a index 
          //bit keeps the count of how many data bits are transmitted
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count <= 0;
            //Here there are two conditions 
            //1.If all the data is transmitted
            //2.If all the data is not yet transmitted
            // Check if we have sent out all bits
            if (r_Bit_Index < 7)
            //here all the data is not yet transmitted
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= TX_DATA_BITS;
              //fsm stays on the same state
            end
            else
            begin
              r_Bit_Index <= 0;
              //
              r_SM_Main   <= TX_STOP_BIT;
             // If all the data is transmitted
             //the Fsm goes to the next state that is stop state indicating all the data bits are transmitted
            end
          end 
        end // case: TX_DATA_BITS
      
      
      // Send out Stop bit.  Stop bit = 1
      //Fsm = 011
      TX_STOP_BIT :
        begin
          o_TX_Serial <= 1'b1;
          //Again high as it was at the time of start bit 
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_STOP_BIT;
          end
          else
          begin
            r_TX_Done     <= 1'b1;
            //As the data is successfully recieved the Tx_done bit is high
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
            //jumping to the next state
            r_TX_Active   <= 1'b0;
          end 
        end // case: TX_STOP_BIT
      
      //Fsm =100
      // Stay here 1 clock
      CLEANUP :
        begin
          r_TX_Done <= 1'b1;
          r_SM_Main <= IDLE;
        end
      //defining default case
      default :
        r_SM_Main <= IDLE;
      endcase
  end
  //hardwired connections
  assign o_TX_Active = r_TX_Active;
  assign o_TX_Done   = r_TX_Done;
endmodule

 
