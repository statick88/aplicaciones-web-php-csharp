# syntax=docker/dockerfile:1
# C# practice image: SDK running `dotnet watch` so source edits rebuild automatically,
# plus the dotnet-ef CLI for EF Core migrations.
FROM mcr.microsoft.com/dotnet/sdk:10.0.403

# dotnet-ef tools live outside the default PATH
ENV PATH="$PATH:/root/.dotnet/tools"
RUN dotnet tool install --global dotnet-ef --version 10.0.14

WORKDIR /app

# Source is bind-mounted from ./src at runtime; dotnet watch detects the changes.
# Use HTTP_PORTS as the single explicit port setting.
ENV ASPNETCORE_HTTP_PORTS=8080
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

EXPOSE 8080

CMD ["dotnet", "watch", "run", "--no-launch-profile"]
