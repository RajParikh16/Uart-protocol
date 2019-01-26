//This will excercise both rx and tx where it sends out 0xAB data via tx and recives 0x3F data via rx
`timescale 1ns/10ps
`include "UART_TX.v"
//Includint the Uart tx file to the testbench
module UART_TB ();
 // Testbench uses a 10 MHz clock
 // Want to interface to 115200 baud UART
 // 10*10^6 / 115200 = 87 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 87;
  parameter c_BIT_PERIOD      = 8600;
  
  reg r_Clock = 0;
  reg r_TX_DV = 0;//inputs to the tx module
  wire w_TX_Active, w_UART_Line; //output for the tx and the rx module where w_UART_line is equivalent to i_Rx_serial  
  wire w_TX_Serial;//output of tx module
  reg [7:0] r_TX_Byte = 0;//input of tx module
  wire w_RX_DV = 0;//outputs of rx module
  wire [7:0] w_RX_Byte;
//instianting rx and tx module 
  //explicit ordering is done
  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) RX_1
    (.i_Clock(r_Clock),
     .i_RX_Serial(w_UART_Line),
     .o_RX_DV(w_RX_DV),
     .o_RX_Byte(w_RX_Byte)
     );
  
  UART_TX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) TX_1
    (.i_Clock(r_Clock),
     .i_TX_DV(r_TX_DV),
     .i_TX_Byte(r_TX_Byte),
     .o_TX_Active(w_TX_Active),
     .o_TX_Serial(w_TX_Serial),
     .o_TX_Done()
     );

  // Keeping the UART Receive input high (default) when
  // UART transmitter is not active
  assign w_UART_Line = w_TX_Active ? w_TX_Serial : 1'b1;
    //This condition states w_TX_Active if 1 then W_UART_Line=W_TX_Active else W_UART_Line = 1'b1 if W_TX_Active if 0
  //for clock repeating edge at 50 ns
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
  
  // Main Testing:
  initial
    begin
      // Tell UART to send a command (exercise TX)
      @(posedge r_Clock);
      @(posedge r_Clock);
      //Here at 2nd postive edge clock i.e at 150 ns
      r_TX_DV   <= 1'b1;
      r_TX_Byte <= 8'h3F;
      @(posedge r_Clock);
      // after another 100 ns i.e at next positive edge clk
      r_TX_DV <= 1'b0;

      // Check that the correct command was received
      @(posedge w_RX_DV);
      if (w_RX_Byte == 8'h3F)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
      $finish();
    end
  
  initial 
  begin
    // Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0,UART_TB);
  end
endmodule
