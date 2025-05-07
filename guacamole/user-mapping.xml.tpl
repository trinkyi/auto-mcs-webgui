<?xml version="1.0" encoding="UTF-8"?>
<!--
  Apache Guacamole user-mapping.xml template
  Renders exactly one user from environment variables.
-->
<user-mapping>

    <!-- Default user: values taken from env -->
    <authorize username="${GUAC_USERNAME}" password="${GUAC_PASSWORD}">
        <connection name="auto-mcs">
            <protocol>vnc</protocol>
            <param name="hostname">${VNC_HOSTNAME}</param>
            <param name="port">${VNC_PORT}</param>
            <param name="password">${VNC_PASSWORD}</param>
        </connection>
    </authorize>

</user-mapping>
