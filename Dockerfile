ARG PYTHON_VERSION=3.10
FROM python:${PYTHON_VERSION}-slim

# The ids of the user and group the app user
ARG UID=1000
ARG GID=1000

# The name of the app user and group
ARG APP_USER=app
ARG APP_GROUP=$APP_USER

# The directory where the application code will be placed
ARG APP_DIR=/home/$APP_USER/code

# Create the app user and group + home directory
RUN groupadd -g ${GID} $APP_GROUP  \
    && useradd --no-log-init -r -u ${UID} -g $APP_USER $APP_GROUP \
    && mkdir /home/$APP_USER \
    && chown $APP_USER:$APP_GROUP /home/$APP_USER  \
    && chmod 755 /home/$APP_USER

# Create and switch to the application source code
WORKDIR $APP_DIR

# Switch to the app user
# Everything after this point will run as the app user with the specific UID / GID
USER app

# Poetry configuration
ARG POETRY_VERSION="1.4"
# See: https://python-poetry.org/docs/configuration/#using-environment-variables
ENV POETRY_HOME="/home/$APP_USER/.local/share/virtualenvs/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=false \
    POETRY_NO_INTERACTION=1

# Update $PATH to include dependency binaries
ENV PATH="${POETRY_HOME}/bin:${PATH}"

# Install poetry
RUN mkdir -p $POETRY_HOME \
    && python3 -m venv $POETRY_HOME \
    && $POETRY_HOME/bin/pip install "poetry==$POETRY_VERSION" \
    && $POETRY_HOME/bin/poetry --version

# See: https://docs.python.org/3/library/venv.html#how-venvs-work
ENV VIRTUAL_ENV="/home/$APP_USER/.local/share/virtualenvs/app"

# Create a new venv for the application
RUN mkdir -p $VIRTUAL_ENV \
    && python -m venv $VIRTUAL_ENV

# Update $PATH to include the apps dependency binaries
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Copy poetry files
COPY --chown=$APP_USER:$APP_GROUP poetry.lock pyproject.toml ./

# Install app dependencies using poetry
RUN poetry install --no-dev --no-root

# Copy the rest of the application
COPY --chown=$APP_USER:$APP_GROUP . ./

COPY --chown=$APP_USER:$APP_GROUP docker-entrypoint.sh /home/$APP_USER/docker-entrypoint.sh
RUN chmod +x /home/$APP_USER/docker-entrypoint.sh
ENTRYPOINT ["/home/app/docker-entrypoint.sh"]

CMD [ "python3", "./main.py" ]

EXPOSE 9000