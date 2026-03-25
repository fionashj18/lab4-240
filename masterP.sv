module masterPattern (
  input  logic [1:0]  shapeLocation,
  input  logic [2:0]  loadShape,
  input  logic        loadShapeNow, CLOCK_100, reset,
  output logic [11:0] masterPattern
);

  logic clock;
  assign clock = CLOCK_100;
  logic [3:0] loaded;
  logic [3:0] location;
  logic loadShapeNow_sync;

  Synchronizer #(1) sync (.async(loadShapeNow), 
                          .clock(clock), 
                          .sync(loadShapeNow_sync));

  // Finding which location shape goes to using Decoder
  Decoder #(4) dec (.I(shapeLocation), 
                    .en(loadShapeNow_sync), 
                    .D(location));

  // Inputs for DFF (OR with feedback keeps loaded bits set once high)
  logic d0, d1, d2, d3;
  assign d0 = location[0] | loaded[0];
  assign d1 = location[1] | loaded[1];
  assign d2 = location[2] | loaded[2];
  assign d3 = location[3] | loaded[3];

  // DFFs to track which locations have been loaded
  DFlipFlop dff0 (.D(d0), .reset_L(~reset), .clock(clock), 
                  .preset_L(1'b1), .Q(loaded[0]));
  DFlipFlop dff1 (.D(d1), .reset_L(~reset), .clock(clock), 
                  .preset_L(1'b1), .Q(loaded[1]));
  DFlipFlop dff2 (.D(d2), .reset_L(~reset), .clock(clock), 
                  .preset_L(1'b1), .Q(loaded[2]));
  DFlipFlop dff3 (.D(d3), .reset_L(~reset), .clock(clock), 
                  .preset_L(1'b1), .Q(loaded[3]));

  // Register enable
  logic enR0, enR1, enR2, enR3;
  assign enR0 = location[0] & ~loaded[0];
  assign enR1 = location[1] & ~loaded[1];
  assign enR2 = location[2] & ~loaded[2];
  assign enR3 = location[3] & ~loaded[3];

  // Registers storing the shape for each location
  Register #(3) reg0 (.D(loadShape), .en(enR0), .clear(reset), 
                      .clock(clock), .Q(masterPattern[2:0]));
  Register #(3) reg1 (.D(loadShape), .en(enR1), .clear(reset), 
                      .clock(clock), .Q(masterPattern[5:3]));
  Register #(3) reg2 (.D(loadShape), .en(enR2), .clear(reset), 
                      .clock(clock), .Q(masterPattern[8:6]));
  Register #(3) reg3 (.D(loadShape), .en(enR3), .clear(reset), 
                      .clock(clock), .Q(masterPattern[11:9]));

endmodule : masterPattern