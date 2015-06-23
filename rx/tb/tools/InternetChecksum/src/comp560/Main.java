/**
 * 
 */
package comp560;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Scanner;

/**
 * @author Robbie Litchfield
 * 
 *         Calculates the internet checksum for the given IPV4/UDP packet. (No
 *         preamble)
 * 
 */
public class Main {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		try {

			// Read in file
			Scanner scan;
			ArrayList<Byte> inputHex = new ArrayList<>();
			try {
				scan = new Scanner(new File(args[0]));

				while (scan.hasNext())
					inputHex.add((byte) (Long.decode("0x" + scan.next()) & 0xFF));
			} catch (FileNotFoundException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			// Parse input
			List<Byte> srcIP = inputHex.subList(0x1A, 0x1E);
			List<Byte> destIP = inputHex.subList(0x1E, 0x22);
			List<Byte> length = inputHex.subList(0x26, 0x28);
			List<Byte> UDPLength = length;
			List<Byte> srcPrt = inputHex.subList(0x22, 0x24);
			List<Byte> destPrt = inputHex.subList(0x24, 0x26);
			List<Byte> data = inputHex.subList(0x2A,
					(int) (0x22 + hexToLong(length)));
			System.out.println("srcIP = " + hexString(srcIP) + ", destIP = "
					+ hexString(destIP) + ", length = " + hexString(length)
					+ ", UDPLength = " + hexString(UDPLength));
			System.out.println("srcPrt = " + hexString(srcPrt) + ", destPrt = "
					+ hexString(destPrt));
			System.out.println("Data = " + hexString(data));

			// Create the pseudo header
			ArrayList<Byte> header = new ArrayList<>();
			header.addAll(srcIP);
			header.addAll(destIP);
			header.add((byte) 0);
			header.add((byte) 0x11);
			header.addAll(UDPLength);
			header.addAll(srcPrt);
			header.addAll(destPrt);
			header.addAll(length);
			header.add((byte) 0);
			header.add((byte) 0);
			header.addAll(data);

			byte[] p = new byte[header.size()];
			for (int i = 0; i < header.size(); i++)
				p[i] = header.get(i);

			// OUtput results
			System.out.println("Checksum = "
					+ hexString(longToHex(calculateChecksum(p)).subList(0x6,
							0x8)));
		} catch (Exception e) {
			System.out
					.println("Usage: java -jar InternetChecksum.jar nameOfHexFile");
			System.out
					.println("File does not include preamble. File is broken into byte chunks with whitespace.");
			e.printStackTrace();

		}
	}

	// http://stackoverflow.com/questions/4113890/how-to-calculate-the-internet-checksum-from-a-byte-in-java
	public static long calculateChecksum(byte[] buf) {
		int length = buf.length;
		int i = 0;

		long sum = 0;
		long data;

		// Handle all pairs
		while (length > 1) {
			// Corrected to include @Andy's edits and various comments on Stack
			// Overflow
			data = (((buf[i] << 8) & 0xFF00) | ((buf[i + 1]) & 0xFF));
			sum += data;
			// 1's complement carry bit correction in 16-bits (detecting sign
			// extension)
			if ((sum & 0xFFFF0000) > 0) {
				sum = sum & 0xFFFF;
				sum += 1;
			}

			i += 2;
			length -= 2;
		}

		// Handle remaining byte in odd length buffers
		if (length > 0) {
			// Corrected to include @Andy's edits and various comments on Stack
			// Overflow
			sum += (buf[i] << 8 & 0xFF00);
			// 1's complement carry bit correction in 16-bits (detecting sign
			// extension)
			if ((sum & 0xFFFF0000) > 0) {
				sum = sum & 0xFFFF;
				sum += 1;
			}
		}

		// Final 1's complement value correction to 16-bits
		sum = ~sum;
		sum = sum & 0xFFFF;
		return sum;

	}

	public static List<Byte> longToHex(long num) {
		ArrayList<Byte> result = new ArrayList<>();
		for (int i = 0; i < 8; i++) {
			result.add((byte) (num & 0xFF));
			num >>>= 8;
		}
		Collections.reverse(result);
		return result;
	}

	public static long hexToLong(List<Byte> hex) {
		long result = 0L;
		for (int i = hex.size() - 1, shift = 0; i >= 0; i--, shift++) {
			result |= ((hex.get(i) & 0xFF << shift) & 0xFF);
		}

		return result;
	}

	public static String hexString(List<Byte> hex) {
		String s = "";
		for (Byte b : hex) {
			s += padZeros(Long.toHexString(b & 0xFF)) + " ";

		}

		return s;
	}

	public static String padZeros(String s) {
		if (s.length() == 1)
			return "0" + s;
		else
			return s;
	}
}
