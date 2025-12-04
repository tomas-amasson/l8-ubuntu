OUTPUT_ARCH( "riscv" )
ENTRY( _start )

SECTIONS
{
  /* O ponto (.) representa o endereço atual de memória. */
  /* Muitos processadores Risc-V simples começam a executar em 0x00000000 */
  . = 0x00000000;

  /* Seção de código (instruções) */
  .text : { 
    *(.text) 
  }

  /* Seção de dados (variáveis, etc) */
  .data : { 
    *(.data) 
  }

  /* Seção BSS (dados não inicializados) */
  .bss : { 
    *(.bss) 
  }
}