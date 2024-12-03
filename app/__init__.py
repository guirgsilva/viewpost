# app/__init__.py
from .app import create_app

# This makes the create_app function directly available when importing from the app package
__all__ = ['create_app']