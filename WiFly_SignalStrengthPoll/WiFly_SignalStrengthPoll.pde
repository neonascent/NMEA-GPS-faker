/*
 * WiFly Signal Strength Polling code, modified from Page Hosting Example, Written by Chris Taylor
 *
 * This code will initialize and test the SC16IS750 UART-SPI bridge, and begin polling the WiFly for signal strength
 */

#include <string.h>

// SC16IS750 Register Definitions
#define THR        0x00 << 3
#define RHR        0x00 << 3
#define IER        0x01 << 3
#define FCR        0x02 << 3
#define IIR        0x02 << 3
#define LCR        0x03 << 3
#define MCR        0x04 << 3
#define LSR        0x05 << 3
#define MSR        0x06 << 3
#define SPR        0x07 << 3
#define TXFIFO     0x08 << 3
#define RXFIFO     0x09 << 3
#define DLAB       0x80 << 3
#define IODIR      0x0A << 3
#define IOSTATE    0x0B << 3
#define IOINTMSK   0x0C << 3
#define IOCTRL     0x0E << 3
#define EFCR       0x0F << 3

#define DLL        0x00 << 3
#define DLM        0x01 << 3
#define EFR        0x02 << 3
#define XON1       0x04 << 3  
#define XON2       0x05 << 3
#define XOFF1      0x06 << 3
#define XOFF2      0x07 << 3

// SPI pin definitions
#define CS         10
#define MOSI       11
#define MISO       12
#define SCK        13

#define ASSOCIATE_TIMEOUT 5000

// hardcoded ssid
String targetSSID = "wireless"; // problems if this is a string that occurs in the scan output, e.g. "rssi", or "SCAN", etc.
String statusString ="";

// Global variables
char incoming_data; 
char TX_Fifo_Address = THR; 

int i = 0;
int j = 0;
int k = 0;
char clr = 0;
char polling = 0;
int pollInterval = 300; //300

// SC16IS750 communication parameters
struct SPI_UART_cfg
{
  char DivL,DivM,DataFormat,Flow;
};

struct SPI_UART_cfg SPI_Uart_config = {
  0x60,0x00,0x03,0x10};

// Wifi parameters
char auth_level[] = "3";
char auth_phrase[] = "example password";
char port_listen[] = "80";
char ssid[] = "uniwide";

void setup()
{
  // SPI pin initialization
  pinMode(MOSI, OUTPUT);
  pinMode(MISO, INPUT);
  pinMode(SCK,OUTPUT);
  pinMode(CS,OUTPUT);
  digitalWrite(CS,HIGH); //disable device 

  SPCR = (1<<SPE)|(1<<MSTR)|(1<<SPR1)|(1<<SPR0);
  clr=SPSR;
  clr=SPDR;
  delay(10); 


  // set LED output pin, and NMEA GPS connection speed
  pinMode(13, OUTPUT);
  Serial.begin(4800);


  //Serial.begin(9600);
  //Serial.println("\n\r\n\rWiFly Shield Terminal Routine");
  if(SPI_Uart_Init()){ // Test SC16IS750 communication
    //Serial.println("Bridge initialized successfully!"); 
  }
  else{ 
    //Serial.println("Could not initialize bridge, locking up.\n\r"); 
    while(1); 
  }

  WiFlyInit();
}

void loop()
{
  i++;
  // Poll for new data in SC16IS750 Recieve buffer 
  if(SPI_Uart_ReadByte(LSR) & 0x01)
  { 
    polling = 1;
    while(polling)
    {
      if((SPI_Uart_ReadByte(LSR) & 0x01))
      {
        incoming_data = SPI_Uart_ReadByte(RHR);
        String newdata = String( incoming_data );
        statusString = statusString + newdata;
      }  
      else
      {
        polling = 0;
      }
    }

  } 
  else if(i > 20000) // if nothing then wait for a while and try again
  {
    if( statusString.indexOf("SCAN:Found") > -1 ) {  // if scan results
      String value = "0";
      int statusIndex = statusString.indexOf(targetSSID);
      // look for value
      // rather than doing a "show rssi" which returns "current last received signal strength" looking like 
      // RSSI=(-4) dBm
      // I'm doing a "scan" so that we have access to full table.  it takes about 3 seconds in my tests
      //SCAN:Found 2
      //Num            SSID   Ch  RSSI   Sec    MAC Address	Suites
      // 1             wireless 01 -34     WEP 1c:bd:b9:80:e4:dd   1104    0
      // 2           The B-team 06 -60   WPAv1 00:24:01:1c:3f:1f TKIPM-TKIP  3104    2
      if(statusIndex > -1 ) {
        // SSID found, work out value
        statusString = statusString.substring(statusIndex+targetSSID.length()+4); 
        value = statusString.substring(0,statusString.indexOf(' '));
      }
      
      // send int as NMEA GPS string, 0 if unfound
      sendValue(value);
    }

    statusString = "";
    SPI_Uart_println("");  
    SPI_Uart_println("scan");
    i = 0;
  } 
}

void select(void)
{
  digitalWrite(CS,LOW);
}

void deselect(void)
{
  digitalWrite(CS,HIGH);
}


char SPI_Uart_Init(void)
// Initialize SC16IS750
{
  char data = 0;

  SPI_Uart_WriteByte(LCR,0x80); // 0x80 to program baudrate
  SPI_Uart_WriteByte(DLL,SPI_Uart_config.DivL); //0x50 = 9600 with Xtal = 12.288MHz
  SPI_Uart_WriteByte(DLM,SPI_Uart_config.DivM); 

  SPI_Uart_WriteByte(LCR, 0xBF); // access EFR register
  SPI_Uart_WriteByte(EFR, SPI_Uart_config.Flow); // enable enhanced registers
  SPI_Uart_WriteByte(LCR, SPI_Uart_config.DataFormat); // 8 data bit, 1 stop bit, no parity
  SPI_Uart_WriteByte(FCR, 0x06); // reset TXFIFO, reset RXFIFO, non FIFO mode
  SPI_Uart_WriteByte(FCR, 0x01); // enable FIFO mode

  // Perform read/write test to check if UART is working
  SPI_Uart_WriteByte(SPR,'H');
  data = SPI_Uart_ReadByte(SPR);

  if(data == 'H'){ 
    return 1; 
  }
  else{ 
    return 0; 
  }

}

void SPI_Uart_WriteByte(char address, char data)
// Write <data> to SC16IS750 register at <address>
{
  long int length;
  char senddata[2];
  senddata[0] = address;
  senddata[1] = data;

  select();
  length = SPI_Write(senddata, 2);
  deselect();
}

long int SPI_Write(char* srcptr, long int length)
// Write string to SC16IS750
{
  for(long int i = 0; i < length; i++)
  {
    spi_transfer(srcptr[i]);
  }
  return length; 
}

void SPI_Uart_WriteArray(char *data, long int NumBytes)
// Write array to SC16IS750 THR
{
  long int length;
  select();
  length = SPI_Write(&TX_Fifo_Address,1);

  while(NumBytes > 16)
  {
    length = SPI_Write(data,16);
    NumBytes -= 16;
    data += 16;
  }
  length = SPI_Write(data,NumBytes);

  deselect();
}

char SPI_Uart_ReadByte(char address)
// Read from SC16IS750 register at <address>
{
  char data;

  address = (address | 0x80);

  select();
  spi_transfer(address);
  data = spi_transfer(0xFF);
  deselect();
  return data;  
}

char WiFlyInit(void)
{
  // Exit command mode if we haven't already
  SPI_Uart_println("");  
  SPI_Uart_println("exit");
  delay(500);

  // Enter command mode
  SPI_Uart_print("$$$");
  delay(500);

  // Reboot to get device into known state
  //Serial.println("Rebooting");
  SPI_Uart_println("reboot");
  delay(3000);

  // Enter command mode
  //Serial.println("Entering command mode.");
  SPI_Uart_print("$$$");
  delay(500);
}


char Wait_On_Response_Char(char num)
// Wait on char number <num> from a response and return it
{
  i = 1;
  while(1)
  {
    if((SPI_Uart_ReadByte(LSR) & 0x01))
    {
      incoming_data = SPI_Uart_ReadByte(RHR);
      //Serial.print(incoming_data, BYTE);
      if(i == num){ 
        return incoming_data; 
      }
      else{ 
        i++; 
      }
    }  
  }
}

void SPI_Uart_println(char *data)
// Print string <data> to SC16IS750 followed by a carriage return
{
  SPI_Uart_WriteArray(data,strlen(data));
  SPI_Uart_WriteByte(THR, 0x0d);
}

void SPI_Uart_print(char *data)
// Print string <data> to SC16IS750 using strlen instead of hard-coded length
{
  SPI_Uart_WriteArray(data,strlen(data));
}

char spi_transfer(volatile char data)
{
  SPDR = data;                    // Start the transmission
  while (!(SPSR & (1<<SPIF)))     // Wait for the end of the transmission
  {
  };
  return SPDR;                    // return the received byte
}

/*
*  GPS NMEA faker functions from: https://github.com/neonascent/NMEA-GPS-faker
 */

void sendValue(String value) {
  digitalWrite(13, HIGH);  
  Serial.println(GPRMC());
  delay(100);
  Serial.println(GPGGA(value));
  delay(100);
  digitalWrite(13, LOW);  
}

String GPRMC() {
  String sentence  = "GPRMC,184332.07,A,1929.459,S,02410.381,E,74.00,16.78,210410,0.0,E,A";
  return "$" + sentence + "*" + calculateChecksum(sentence);
}

String GPGGA(String Altitude) {
  String sentence  = "GPGGA,184333.07,1929.439,S,02410.387,E,1,04,2.8,"+String(Altitude)+",M,0,M,,0000";
  return "$" + sentence + "*" + calculateChecksum(sentence);
}


String calculateChecksum(String instring) {

  int thisChecksum = 0;
  for (int i = 0; i < instring.length(); i++) {
    thisChecksum ^= (byte)instring[i];
  }

  return String(thisChecksum, HEX);
}





