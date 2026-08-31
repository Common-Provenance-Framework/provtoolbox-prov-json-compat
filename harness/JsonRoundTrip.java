import org.openprovenance.prov.core.json.serialization.ProvDeserialiser;
import org.openprovenance.prov.core.json.serialization.ProvSerialiser;
import org.openprovenance.prov.model.Document;

import java.io.*;
import java.nio.file.*;

public class JsonRoundTrip {
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java JsonRoundTrip <input.json> [output.json]");
            System.exit(1);
        }

        String inputPath = args[0];
        String outputPath = args.length > 1 ? args[1] : null;

        System.out.println("=== PROV-JSON Round-Trip Test ===");
        System.out.println("Input: " + inputPath);

        // Step 1: Read input
        String inputJson;
        try {
            inputJson = Files.readString(Path.of(inputPath));
        } catch (IOException e) {
            System.out.println("VERDICT: ERROR_READ");
            System.out.println("REASON: " + e.getMessage());
            System.exit(2);
            return;
        }

        // Step 2: Deserialize
        Document doc;
        try {
            ProvDeserialiser deserial = new ProvDeserialiser();
            doc = deserial.deserialiseDocument(new File(inputPath));
            System.out.println("PARSE: OK");
        } catch (Exception e) {
            System.out.println("VERDICT: PARSE_FAILED");
            System.out.println("EXCEPTION: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            Throwable cause = e.getCause();
            while (cause != null) {
                System.out.println("  CAUSED_BY: " + cause.getClass().getSimpleName() + ": " + cause.getMessage());
                cause = cause.getCause();
            }
            System.exit(0);
            return;
        }

        // Step 3: Serialize back
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try {
            ProvSerialiser serial = new ProvSerialiser();
            serial.serialiseDocument(baos, doc, true);
            System.out.println("SERIALIZE: OK");
        } catch (Exception e) {
            System.out.println("VERDICT: SERIALIZE_FAILED");
            System.out.println("EXCEPTION: " + e.getClass().getSimpleName() + ": " + e.getMessage());
            System.exit(0);
            return;
        }

        String outputJson = baos.toString();

        // Step 4: Write output if requested
        if (outputPath != null) {
            try {
                Files.writeString(Path.of(outputPath), outputJson);
            } catch (IOException e) {
                System.out.println("WARNING: Could not write output: " + e.getMessage());
            }
        }

        // Step 5: Print output
        System.out.println("\n--- OUTPUT JSON ---");
        System.out.println(outputJson);
        System.out.println("--- END OUTPUT ---");

        // Step 6: Basic comparison
        String inputNorm = inputJson.replaceAll("\\s+", "");
        String outputNorm = outputJson.replaceAll("\\s+", "");
        if (inputNorm.equals(outputNorm)) {
            System.out.println("\nVERDICT: ROUND_TRIP_IDENTICAL");
        } else {
            System.out.println("\nVERDICT: ROUND_TRIP_CHANGED");
        }
    }
}
