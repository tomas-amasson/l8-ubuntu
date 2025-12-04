module riscvmulti (
    input clk,
    input reset,

    input  [31:0] readdata,
    output [31:0] address,
    output we,
    output [31:0] writedata
);

assign address = (state == FETCH_INSTR || state == WAIT_INSTR) ? pc: (state == LOAD || state == WAIT_DATA || state == STORE) ? read_adr: 32'b0;
assign we = isS && state == STORE;
assign writedata = ULAresult;

logic [31:0] Registers [0:31];

reg  [31:0] pc = 0;
wire [31:0] nextpc = (isB && take_branch)? pc + ULAresult: (isJ)? pc + immJ: (isAuipc)? pc + ULAresult: pc + 4;
reg  [31:0] Instr_reg;
reg  [31:0] ULAa;
reg  [31:0] ULAb;
reg  [31:0] ULAresult;
reg  [31:0] ULAout;
reg  [31:0] read_adr;

wire WriteBackEN = ((state == EXECUTE  & !isL   || state == WAIT_DATA) && (isR || isI || isJ || isLui || isL));
wire [31:0] WriteBackData = ULAresult;

reg isR, isI, isS, isL, isLui, isAuipc, isB, isJ;
reg take_branch;

wire [4:0] rd     = Instr_reg[11:7];
wire [4:0] rs1    = Instr_reg[19:15];
wire [4:0] rs2    = Instr_reg[24:20];
wire [6:0] opcode = Instr_reg[6:0];
wire [2:0] f3     = Instr_reg[14:12];
wire [6:0] f7     = Instr_reg[31:25];

wire [31:0] immI = {{20{Instr_reg[31]}}, Instr_reg[31:20]}; 
wire [31:0] immS = {{20{Instr_reg[31]}}, Instr_reg[31:25], Instr_reg[11:7]};
wire [31:0] immB = {{20{Instr_reg[31]}}, Instr_reg[7], Instr_reg[30:25], Instr_reg[11:8], 1'b0};
wire [31:0] immU = {Instr_reg[31:12], 12'b0};
wire [31:0] immJ = {{11{Instr_reg[31]}}, Instr_reg[31], Instr_reg[19:12], Instr_reg[20], Instr_reg[30:21], 1'b0};


always @(*) begin
    isR = 0;    
    isI = 0;    
    isS = 0;
    isL = 0;
    isLui = 0;
    isAuipc = 0;
    isB = 0;
    isJ = 0;
    take_branch = 0;

    case(opcode) 
    7'b0110011 : isR     = 1;
    7'b0010011 : isI     = 1;
    7'b0100011 : isS     = 1;
    7'b0110111 : isLui   = 1;
    7'b0010111 : isAuipc = 1;
    7'b0000011 : isL     = 1;
    7'b1100011 : isB     = 1;
    7'b1101111 : isJ     = 1;
    endcase

    case(f3)
    3'b000: take_branch = ULAa == ULAb;        
    3'b001: take_branch = ULAa != ULAb;
    3'b100: take_branch = $signed(ULAa) < $signed(ULAb);
    3'b101: take_branch = $signed(ULAa) >= $signed(ULAb);
    3'b110: take_branch = ULAa < ULAb;
    3'b111: take_branch = ULAa >= ULAb;        
    endcase


    if (isR) begin
        if (f7 == 7'b0000000) begin
            case(f3)
            3'b000 : ULAresult = ULAa + ULAb;            
            3'b001 : ULAresult = ULAa << ULAb[4:0];            
            3'b010 : ULAresult = $signed(ULAa) < $signed(ULAb)? 1: 0;            
            3'b011 : ULAresult = ULAa < ULAb? 1: 0;            
            3'b100 : ULAresult = ULAa ^ ULAb;
            3'b101 : ULAresult = ULAa >> ULAb[4:0];
            3'b110 : ULAresult = ULAa | ULAb;
            3'b111 : ULAresult = ULAa & ULAb;            
            endcase
        end

        else if (f7 == 7'b0100000) begin
            case(f3)
            3'b000: ULAresult = ULAa - ULAb;
            3'b101: ULAresult = $signed(ULAa) >>> ULAb[4:0];
            endcase
        end
    end
    else if (isI) begin
        case(f3)
        3'b000: ULAresult = ULAa + immI;
        3'b010: ULAresult = $signed(ULAa) < $signed(immI)? 32'b1: 32'b0;
        3'b011: ULAresult = ULAa < immI? 32'b1: 32'b0;
        3'b100: ULAresult = ULAa ^ immI;
        3'b110: ULAresult = ULAa | immI;
        3'b111: ULAresult = ULAa & immI;
        3'b001: ULAresult = ULAa << immI[4:0];
        3'b101: begin
            if (f7 == 7'b0000000)
                ULAresult = ULAa >> immI[4:0];
            else if (f7 == 7'b0100000)
                ULAresult = $signed(ULAa) >>> immI[4:0];
        end
        endcase
    end

    else if (isLui || isAuipc) begin
        ULAresult = immU;
    end

    else if (isJ) begin
        ULAresult = pc + 4;
    end

    else if (isB) begin
        ULAresult = immB;
    end

    else if (isL) begin
        read_adr = ULAa + immI;
        case(f3)
        3'b000: begin
            case(read_adr[1:0])
            2'b00: ULAresult = {{24{readdata[7]}},  readdata[7:0]};
            2'b01: ULAresult = {{24{readdata[15]}}, readdata[15:8]};
            2'b10: ULAresult = {{24{readdata[23]}}, readdata[23:16]};
            2'b11: ULAresult = {{24{readdata[31]}}, readdata[31:24]};
            endcase
        end

        3'b001: begin
            case(read_adr[1])
            1'b0: ULAresult = {{16{readdata[15]}}, readdata[15:0]};
            1'b1: ULAresult = {{16{readdata[31]}}, readdata[31:16]};
            endcase
        end
        3'b010: ULAresult = readdata;
        3'b100: begin
            case(read_adr[1:0])
            2'b00: ULAresult = {24'b0, readdata[7:0]};
            2'b01: ULAresult = {24'b0, readdata[15:8]};
            2'b10: ULAresult = {24'b0, readdata[23:16]}; 
            2'b11: ULAresult = {24'b0, readdata[31:24]};
            endcase
        end
        3'b101: begin
            case(read_adr[1])
            1'b0: ULAresult = {16'b0, readdata[15:0]};
            1'b1: ULAresult = {16'b0, readdata[31:16]};
            endcase
        end
        endcase
    end

    else if (isS) begin
        read_adr = ULAa + immS;

        case(f3)
        3'b000: begin
            ULAresult = {24'b0, ULAb[7:0]};
        end
        3'b001: begin
            case(read_adr[1])
            1'b0: ULAresult = {16'b0, ULAb[15:0]};
            1'b1: ULAresult = {16'b0, ULAb[31:16]};
            endcase
        end
        3'b010: ULAresult = ULAb;
        endcase
    end
end 





localparam FETCH_INSTR  = 0;
localparam WAIT_INSTR   = 1;
localparam FETCH_REGS   = 2;
localparam EXECUTE      = 3;
localparam LOAD         = 4;
localparam WAIT_DATA    = 5;
localparam STORE        = 6;

reg [2:0] state = FETCH_INSTR;

always @(posedge clk) begin
    if (reset) begin
        pc <= 0;
        ULAa <= 0;
        ULAb <= 0;
        state <= 0;
        Instr_reg <= 0;
    end
    else begin


        if (WriteBackEN) begin
            Registers[rd] <= WriteBackData;
        end


        if (state == FETCH_INSTR) begin

            state <= WAIT_INSTR;
        end

        else if (state == WAIT_INSTR) begin
            Instr_reg <= readdata;
            state <= FETCH_REGS;
        end

        else if (state == FETCH_REGS) begin

            ULAa <= Registers[rs1];
            ULAb <= Registers[rs2];


            state <= EXECUTE;
        end

        else if (state == EXECUTE) begin
            ULAout <= ULAresult;
            pc <= nextpc;


            if (isL) begin

                state <= LOAD;
            end

            else if (isS) begin

                state <= STORE;
            end

            else begin

                state <= FETCH_INSTR;
            end
        end

        else if (state == LOAD) begin

            state <= WAIT_DATA;
        end

        else if (state == WAIT_DATA) begin
            state <= FETCH_INSTR;
        end

        else if (state == STORE) begin
            state <= FETCH_INSTR;
        end
    end
    

end

endmodule