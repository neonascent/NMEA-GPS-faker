//Created August 15 2006
//Heather Dewey-Hagborg
//http://www.arduino.cc
  // we encode GPS altitude data in here


    // GPRMC - http://aprs.gids.nl/nmea/#rmc - 
  /* 
   $GPRMC,184332.07,A,1929.459,S,02410.381,E,74.00,16.78,210410,0.0,E,A*2B
   1   220516     Time Stamp
   2   A          validity - A-ok, V-invalid
   3   5133.82    current Latitude
   4   N          North/South
   5   00042.24   current Longitude
   6   W          East/West
   7   173.8      Speed in knots
   8   231.8      True course
   9   130694     Date Stamp
   10  004.2      Variation
   11  W          East/West
   12  *70        checksum
   */

  // GPGGA - http://aprs.gids.nl/nmea/#gga 
  /*
    $GPGGA,184333.07,1929.439,S,02410.387,E,1,04,2.8,100.00,M,-33.9,M,,0000*65
   
   Name	Example Data	Description
   Sentence Identifier	$GPGGA	Global Positioning System Fix Data
   Time	170834	17:08:34 Z
   Latitude	4124.8963, N	41d 24.8963' N or 41d 24' 54" N
   Longitude	08151.6838, W	81d 51.6838' W or 81d 51' 41" W
   Fix Quality:
   - 0 = Invalid
   - 1 = GPS fix
   - 2 = DGPS fix	1	Data is from a GPS fix
   Number of Satellites	05	5 Satellites are in view
   Horizontal Dilution of Precision (HDOP)	1.5	Relative accuracy of horizontal position
   Altitude	280.2, M	280.2 meters above mean sea level
   Height of geoid above WGS84 ellipsoid	-34.0, M	-34.0 meters
   Time since last DGPS update	blank	No last update
   DGPS reference station id	blank	No station id
   Checksum	*75	Used by program to check for transmission errors
   */

  // GPGLL - http://aprs.gids.nl/nmea/#gll
  /*
  $GPGLL,1929.420,S,02410.393,E,184334.07,A,A*71
   1    5133.81   Current latitude
   2    N         North/South
   3    00042.25  Current longitude
   4    W         East/West
   5    *75       checksum
   */

  // GPVTG - http://aprs.gids.nl/nmea/#vtg
  /*
  $GPVTG,16.78,T,,M,74.00,N,137.05,K,A*36
   1    = Track made good
   2    = Fixed text 'T' indicates that track made good is relative to true north
   3    = not used
   4    = not used
   5    = Speed over ground in knots
   6    = Fixed text 'N' indicates that speed over ground in in knots
   7    = Speed over ground in kilometers/hour
   8    = Fixed text 'K' indicates that speed over ground is in kilometers/hour
   9    = Checksum
   */

 /* http://rietman.wordpress.com/2008/09/25/how-to-calculate-the-nmea-checksum/
   In Java script:
   var checksum = 0; 
   for(var i = 0; i < stringToCalculateTheChecksumOver.length; i++) { 
   checksum = checksum ^ stringToCalculateTheChecksumOver.charCodeAt(i); 
   }
   
   In C#:
   int checksum = 0; 
   for (inti = 0; i < stringToCalculateTheChecksumOver.length; i++){ 
   checksum ^= Convert.ToByte(sentence[i]);}
   
   In VB.Net:
   Dim checksum as Integer = 0 
   For Each Character As Char In stringToCalculateTheChecksumOver  
   checksum = checksum Xor Convert.ToByte(Character) 
   Next 
   }*/

/*
* NOTES: 
 * + camera needs checksum
 * + does camera need all sentences?
 * 
 */

  int counter = 1;

void setup() {
  pinMode(13, OUTPUT);
  Serial.begin(4800);
}

void loop()
{

  sendValue(counter);
  counter++;
  delay(500);

}

void sendValue(int value) {
  digitalWrite(13, HIGH);  
  Serial.println(GPRMC());
  Serial.println(GPGGA(value));
  digitalWrite(13, LOW);  
}

String GPRMC() {
  String sentence  = "GPRMC,184332.07,A,1929.459,S,02410.381,E,74.00,16.78,210410,0.0,E,A";
  return "$" + sentence + "*" + calculateChecksum(sentence);
}

String GPGGA(int Altitude) {
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



