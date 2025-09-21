package com.converter.services;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

@Component
public class NginxSetupRunner {

    @Value("${nginx.subdomain}")
    private String subdomain;

    @Value("${nginx.port}")
    private String appPort;

    @Value("${nginx.email}")
    private String email;

    @PostConstruct
    public void setupNginxBeforeAppStart() throws Exception {
        // Copy script to /tmp or /opt
        File tempScript = File.createTempFile("setup-nginx", ".sh");
        try (InputStream in = new ClassPathResource("scripts/setup-nginx-subdomain.sh").getInputStream()) {
            Files.copy(in, tempScript.toPath(), StandardCopyOption.REPLACE_EXISTING);
        }
        tempScript.setExecutable(true);

        // Run script with parameters
        String fullSubdomain = subdomain + ".kpawan.com";
        ProcessBuilder builder = new ProcessBuilder(
                "bash", tempScript.getAbsolutePath(),
                subdomain, appPort, email
        );
        builder.redirectErrorStream(true);
        Process process = builder.start();

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println("[Nginx Setup] " + line);
            }
        }

        int exitCode = process.waitFor();
        if (exitCode != 0) {
            throw new RuntimeException("❌ Failed to set up nginx for subdomain: " + fullSubdomain);
        }

        System.out.println("✅ Nginx + SSL ready for: " + fullSubdomain);
    }

}
